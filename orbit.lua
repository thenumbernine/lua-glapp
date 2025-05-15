-- This class adds orbit trackball behavior to a GLApp (or GLApp subclass).
-- It also calls View.apply on the class if it has not yet already been applied to the class
local class = require 'ext.class'
local sdl = require 'sdl'
local SDLApp = require 'sdl.app'
local vec3d = require 'vec-ffi.vec3d'
local quatd = require 'vec-ffi.quatd'
local Mouse = require 'glapp.mouse'

-- a case for a preprocessing ext.load shim layer ...
local keyUpEventType
local keyDownEventType
local mouseMotionEventType
local mouseWheelEventType
local handleKeyUpDown
if SDLApp.sdlMajorVersion == 2 then
	keyUpEventType = sdl.SDL_KEYUP
	keyDownEventType = sdl.SDL_KEYDOWN
	mouseMotionEventType = sdl.SDL_MOUSEMOTION
	mouseWheelEventType = sdl.SDL_MOUSEWHEEL
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
	mouseMotionEventType = sdl.SDL_EVENT_MOUSE_MOTION
	mouseWheelEventType = sdl.SDL_EVENT_MOUSE_WHEEL
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
	cl = cl or require 'glapp'

	cl = class(cl)

	-- make sure we have self.view == a View object
	if not cl.viewApplied then
		cl = class(require 'glapp.view'.apply(cl))
	end

	-- and TODO same thing for Mouse.apply?

	function cl:init(...)
		cl.super.init(self, ...)

		self.mouse = self.mouse or Mouse()

		self.leftShiftDown = false
		self.rightShiftDown = false
		self.leftGuiDown = false
		self.rightGuiDown = false
		self.leftAltDown = false
		self.rightAltDown = false
	end

	function cl:update(...)
		if self.mouse then	-- event() is called before init()
			self.mouse:update()
		end
		return cl.super.update(self, ...)
	end

	function cl:event(eventPtr)
		cl.super.event(self, eventPtr)

		local canHandleMouse = true
		--local canHandleKeyboard = true
		if ImGuiApp and ImGuiApp:isa(self) then
			local ig = require 'imgui'
			canHandleMouse = not ig.igGetIO()[0].WantCaptureMouse
			--canHandleKeyboard = not ig.igGetIO()[0].WantCaptureKeyboard
		end

		local shiftDown = self.leftShiftDown or self.rightShiftDown
		local guiDown = self.leftGuiDown or self.rightGuiDown
		local altDown = self.leftAltDown or self.rightAltDown
		if eventPtr[0].type == mouseMotionEventType
		or eventPtr[0].type == mouseWheelEventType
		then
			if canHandleMouse then
				local dx, dy
				if eventPtr[0].type == mouseMotionEventType then
					dx = eventPtr[0].motion.xrel
					dy = eventPtr[0].motion.yrel
				else
					dx = 10 * eventPtr[0].wheel.x
					dy = 10 * eventPtr[0].wheel.y
				end
				if (self.mouse and self.mouse.leftDown and not guiDown)
				or eventPtr[0].type == mouseWheelEventType
				then
					self:mouseDownEvent(dx, dy, shiftDown, guiDown, altDown)
				end
			end
		elseif eventPtr[0].type == keyUpEventType
		or eventPtr[0].type == keyDownEventType
		then
			handleKeyUpDown(self, eventPtr)
		end
	end

	function cl:mouseDownEvent(dx, dy, shiftDown, guiDown, altDown)
		if shiftDown then
			if dx ~= 0 or dy ~= 0 then
				if self.view.ortho then
					self.view.orthoSize = self.view.orthoSize * math.exp(dy * -.03)
				else
					self.view.pos = (self.view.pos - self.view.orbit) * math.exp(dy * -.03) + self.view.orbit
				end
			end
		elseif altDown then
			local dist = (self.view.pos - self.view.orbit):length()
			self.view.orbit = self.view.orbit + self.view.angle:rotate(vec3d(-dx,dy,0) * (dist / self.height))
			self.view.pos = self.view.angle:zAxis() * dist + self.view.orbit
		else
			if dx ~= 0 or dy ~= 0 then
				if self.view.ortho then
					local aspectRatio = self.width / self.height
					local fdx = -2 * dx / self.width * self.view.orthoSize * aspectRatio
					local fdy = 2 * dy / self.height * self.view.orthoSize
					self.view.pos = self.view.pos + self.view.angle:rotate(vec3d(fdx, fdy, 0))
				else
					local magn = math.sqrt(dx * dx + dy * dy)
					magn = magn * math.tan(math.rad(.5 * self.view.fovY))
					local fdx = dx / magn
					local fdy = dy / magn
					local rotation = quatd():fromAngleAxis(-fdy, -fdx, 0, magn)
					self.view.angle = (self.view.angle * rotation):normalize()
					self.view.pos = self.view.angle:zAxis() * (self.view.pos - self.view.orbit):length() + self.view.orbit
				end
			end
		end
	end

	-- subclass so the caller doesn't override these new functions...
	return cl:subclass()
end
