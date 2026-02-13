-- This class adds orbit trackball behavior to a GLApp (or GLApp subclass).
-- It also calls View.apply on the class if it has not yet already been applied to the class
local class = require 'ext.class'
local sdl = require 'sdl'
local SDLApp = require 'sdl.app'
local vec3d = require 'vec-ffi.vec3d'
local vec4f = require 'vec-ffi.vec4f'
local quatd = require 'vec-ffi.quatd'

-- a case for a preprocessing ext.load shim layer ...
local keyUpEventType
local keyDownEventType
local handleKeyUpDown
if SDLApp.sdlMajorVersion == 2 then
	keyUpEventType = sdl.SDL_KEYUP
	keyDownEventType = sdl.SDL_KEYDOWN
	function handleKeyUpDown(self, eventPtr)
		local down = eventPtr[0].type == keyDownEventType
		if eventPtr[0].key.keysym.sym == sdl.SDLK_LSHIFT then
			self.leftShiftDown = down
		elseif eventPtr[0].key.keysym.sym == sdl.SDLK_RSHIFT then
			self.rightShiftDown = down
		elseif eventPtr[0].key.keysym.sym == sdl.SDLK_LGUI then
			self.leftGuiDown = down
		elseif eventPtr[0].key.keysym.sym == sdl.SDLK_RGUI then
			self.rightGuiDown = down
		elseif eventPtr[0].key.keysym.sym == sdl.SDLK_LALT then
			self.leftAltDown = down
		elseif eventPtr[0].key.keysym.sym == sdl.SDLK_RALT then
			self.rightAltDown = down
		end
	end
elseif SDLApp.sdlMajorVersion == 3 then
	keyUpEventType = sdl.SDL_EVENT_KEY_UP
	keyDownEventType = sdl.SDL_EVENT_KEY_DOWN
	function handleKeyUpDown(self, eventPtr)
		local down = eventPtr[0].type == keyDownEventType
		if eventPtr[0].key.key == sdl.SDLK_LSHIFT then
			self.leftShiftDown = down
		elseif eventPtr[0].key.key == sdl.SDLK_RSHIFT then
			self.rightShiftDown = down
		elseif eventPtr[0].key.key == sdl.SDLK_LGUI then
			self.leftGuiDown = down
		elseif eventPtr[0].key.key == sdl.SDLK_RGUI then
			self.rightGuiDown = down
		elseif eventPtr[0].key.key == sdl.SDLK_LALT then
			self.leftAltDown = down
		elseif eventPtr[0].key.key == sdl.SDLK_RALT then
			self.rightAltDown = down
		end
	end
else
	error("SDLApp.sdlMajorVersion is unknown: "..require'ext.tolua'(SDLApp.sdlMajorVersion))
end

local result, ImGuiApp = pcall(require, 'imgui.app')
ImGuiApp = result and ImGuiApp

return function(cl)
	-- if no class is specified then assume the class is GLApp by default
	cl = cl or require 'gl.app'

	cl = class(cl)

	-- make sure we have self.view == a View object
	if not cl.viewApplied then
		cl = class(require 'app3d.view'.apply(cl))
	end
	-- and same with .mouse
	if not cl.mouseApplied then
		cl = class(require 'sdl.mouse'.apply(cl))
	end

	function cl:init(...)
		cl.super.init(self, ...)

		self.leftShiftDown = false
		self.rightShiftDown = false
		self.leftGuiDown = false
		self.rightGuiDown = false
		self.leftAltDown = false
		self.rightAltDown = false
	end

	function cl:update(...)
		local mouse = self.mouse
		cl.super.update(self, ...)

		if mouse.fingerPinchDelta ~= 0 then
			local pos1 = mouse.activeFingersInOrder[1].pos
			self:mouseDownEvent(0, mouse.fingerPinchDelta, true, nil, nil, pos1.x, pos1.y)
		end

		local shiftDown = self.leftShiftDown or self.rightShiftDown
		local guiDown = self.leftGuiDown or self.rightGuiDown
		local altDown = self.leftAltDown or self.rightAltDown

		if mouse.wheelDelta.x ~= 0
		or mouse.wheelDelta.y ~= 0
		then
			self:mouseDownEvent(-.01 * mouse.wheelDelta.x, -.01 * mouse.wheelDelta.y, shiftDown, guiDown, altDown, mouse.pos.x, mouse.pos.y)
		end

		if (
			mouse.deltaPos.x ~= 0
			or mouse.deltaPos.y ~= 0
		)
		and mouse.leftDown
		and not guiDown
		then
			self:mouseDownEvent(mouse.deltaPos.x, mouse.deltaPos.y, shiftDown, guiDown, altDown, mouse.pos.x, mouse.pos.y)
		end
	end

	function cl:event(e)
		local mouse = self.mouse

		local canHandleMouse = true
		--local canHandleKeyboard = true
		if ImGuiApp and ImGuiApp:isa(self) then
			local ig = require 'imgui'
			canHandleMouse = not ig.igGetIO()[0].WantCaptureMouse
			--canHandleKeyboard = not ig.igGetIO()[0].WantCaptureKeyboard
		end

		mouse.cantHandleEvent = not canHandleMouse
		cl.super.event(self, e)

		if e.type == keyUpEventType
		or e.type == keyDownEventType
		then
			handleKeyUpDown(self, e)
		end
	end

	function cl:mouseDownEvent(dx, dy, shiftDown, guiDown, altDown, x, y)
		if shiftDown then
			if self.view.ortho then
				-- ortho = shrink / grow view size
				self.view.orthoSize = self.view.orthoSize * math.exp(-10 * dy)
			else
				-- frustum = zoom dist in and out
				self.view.pos = (self.view.pos - self.view.orbit) * math.exp(-10 * dy) + self.view.orbit
			end
		elseif altDown then
			if self.view.ortho then
				-- ortho = rotate view
				-- will this be this frames delta or last frames delta, eh?
				local aspectRatio = self.width / self.height
				local rx = aspectRatio * (self.mouse.lastPos.x - .5) * 2
				local ry = (self.mouse.lastPos.y - .5) * 2
				local rx2 = aspectRatio * (self.mouse.pos.x - .5) * 2
				local ry2 = (self.mouse.pos.y - .5) * 2
				local angle = math.asin((rx2 * ry - ry2 * rx) / math.sqrt((rx^2 + ry^2) * (rx2^2 + ry2^2)))
				local rotation = quatd():fromAngleAxis(0, 0, 1, math.deg(angle))
				self.view.angle = (self.view.angle * rotation):normalize()
			else
				-- frustum = move orbit center
				local dist = (self.view.pos - self.view.orbit):length()
				self.view.orbit = self.view.orbit + self.view.angle:rotate(vec3d(-dx, -dy, 0) * dist)
				self.view.pos = self.view.angle:zAxis() * dist + self.view.orbit
			end
		else
			if self.view.ortho then
				-- ortho = drag
				local aspectRatio = self.width / self.height
				local fdx = -2 * dx * self.view.orthoSize * aspectRatio
				local fdy = -2 * dy * self.view.orthoSize
				self.view.pos = self.view.pos + self.view.angle:rotate(vec3d(fdx, fdy, 0))
			else
				-- frustum = rotate around orbit
				local magn = math.sqrt(dx * dx + dy * dy)
				local fdx = dx / magn
				local fdy = dy / magn
				magn = magn * 1000 * math.tan(math.rad(.5 * self.view.fovY))
				local rotation = quatd():fromAngleAxis(fdy, -fdx, 0, magn)
				self.view.angle = (self.view.angle * rotation):normalize()
				self.view.pos = self.view.angle:zAxis() * (self.view.pos - self.view.orbit):length() + self.view.orbit
			end
		end
	end

	-- subclass so the caller doesn't override these new functions...
	return cl:subclass()
end
