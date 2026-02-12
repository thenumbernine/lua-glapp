-- This class adds orbit trackball behavior to a GLApp (or GLApp subclass).
-- It also calls View.apply on the class if it has not yet already been applied to the class
local class = require 'ext.class'
local table = require 'ext.table'
local sdl = require 'sdl'
local SDLApp = require 'sdl.app'
local vec3d = require 'vec-ffi.vec3d'
local vec4f = require 'vec-ffi.vec4f'
local quatd = require 'vec-ffi.quatd'
local Mouse = require 'glapp.mouse'

-- a case for a preprocessing ext.load shim layer ...
local keyUpEventType
local keyDownEventType
local mouseMotionEventType
local mouseWheelEventType
local handleKeyUpDown
local fingerUpEventType
local fingerDownEventType
local fingerMotionEventType
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
	fingerUpEventType = sdl.SDL_EVENT_FINGER_UP
	fingerDownEventType = sdl.SDL_EVENT_FINGER_DOWN
	fingerMotionEventType = sdl.SDL_EVENT_FINGER_MOTION
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

		self.activeFingers = {}
		self.activeFingersInOrder = table()
	end

	function cl:update(...)
		-- process multi-finger events:
		self.doingMultiTouchGesture = nil
		if self.gotFingerEvent then
			local numTouches = 0
			local prevNumTouches = #self.activeFingersInOrder
			-- is there a promise that activeFingers IDs are sequential?
			for fingerID, finger in pairs(self.activeFingers) do
				numTouches=numTouches+1
				self.activeFingersInOrder[numTouches] = finger
			end
			for j=numTouches+1,prevNumTouches do
				self.activeFingersInOrder[j] = nil
			end
--DEBUG:print('we currently have', numTouches, 'touches, previously', prevNumTouches)

			local f1, f2, pos1, pos2
			if numTouches >= 2 then
				f1, f2 = table.unpack(self.activeFingersInOrder)
				pos1, pos2 = f1.pos, f2.pos
				self.multiTouchDistSq = (pos2.x - pos1.x)^2 + (pos2.y - pos1.y)^2
			else
				self.multiTouchDistSq = nil
			end

			if self.multiTouchDistSq
			and self.lastMultiTouchDistSq
			and self.multiTouchDistSq ~= self.lastMultiTouchDistSq
			then
				local toDist = math.sqrt(self.multiTouchDistSq)
				local fromDist = math.sqrt(self.lastMultiTouchDistSq)
				local zoomChange = toDist - fromDist
--DEBUG:print('got zoom change', zoomChange, 'from-dist', fromDist, 'to-pts', pos1, pos2, 'to-dist', toDist)
				-- process a zoom ...
				-- TODO instead of calling orbit:mouseDownEvent, since it only handles rotate vs pan vs zoom, how about name its functions that?
				-- zoom
				self:mouseDownEvent(0, 100 * zoomChange, true, nil, nil, pos1.x, pos1.y)
				-- tell our mouse event handler to ignore events coming from touches
				self.doingMultiTouchGesture = true
			end
			self.lastMultiTouchDistSq = self.multiTouchDistSq
			self.gotFingerEvent = nil
		end

		if self.mouse then	-- event() is called before init()
			self.mouse:update()
		end
		return cl.super.update(self, ...)
	end

	function cl:event(e)
		cl.super.event(self, e)

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
		if e.type == mouseMotionEventType
		or e.type == mouseWheelEventType
		then
			if canHandleMouse
			-- if it's a mouse event
			-- and it came from a touch event
			-- but we're doing a multi-touch gesture
			-- then skip processing the mouse event
			and not (
				self.doingMultiTouchGesture
				and e.motion.which == sdl.SDL_TOUCH_MOUSEID
			)
			then
				local dx, dy, x, y
				if e.type == mouseMotionEventType then
					x = e.motion.x
					y = e.motion.y
					dx = e.motion.xrel
					dy = e.motion.yrel
				else
					x = e.wheel.x
					y = e.wheel.y
					dx = 10 * e.wheel.x
					dy = 10 * e.wheel.y
				end
				if (self.mouse and self.mouse.leftDown and not guiDown)
				or e.type == mouseWheelEventType
				then
					self:mouseDownEvent(dx, dy, shiftDown, guiDown, altDown, x, y)
				end
			end
		elseif e.type == fingerDownEventType then
			local fingerID = tonumber(e.tfinger.fingerID)
			self.activeFingers[fingerID] = {
				id = fingerID,
				pos = vec4f(
					e.tfinger.x,
					e.tfinger.y,
					e.tfinger.dx,
					e.tfinger.dy
				),
			}
			self.gotFingerEvent = true
--DEBUG:print('setting finger', fingerID, 'to', self.activeFingers[fingerID].pos)
		elseif e.type == fingerUpEventType then
			local fingerID = tonumber(e.tfinger.fingerID)
--DEBUG:print('clearing finger', fingerID)
			self.activeFingers[fingerID] = nil
			self.gotFingerEvent = true
		elseif e.type == fingerMotionEventType then
			local fingerID = tonumber(e.tfinger.fingerID)
			-- looks like sdl3 doesnt have multigesture like sdl2 did
			-- and sdl3 sends each finger event separately unlike javascript does
			-- and sdl3 , for query multiple touches with SDL_GetTouchFingers it seems to allocate a structure that needs to be freed ... which I don't want ot do every frame ...
			local finger = self.activeFingers[fingerID]
			if not finger then
				-- motion before down ...
				self.activeFingers[fingerID] = {
					id = fingerID,
					pos = vec4f(
						e.tfinger.x,
						e.tfinger.y,
						e.tfinger.dx,
						e.tfinger.dy
					),
				}
--DEBUG:print('motion setting finger', fingerID, 'to', self.activeFingers[fingerID].pos)
			else
				finger.pos.x, finger.pos.y, finger.pos.z, finger.pos.w
				= e.tfinger.x, e.tfinger.y, e.tfinger.dx, e.tfinger.dy
--DEBUG:print('updating finger', fingerID, 'to', finger.pos)
			end
			-- what about finger events that dont get a down event?
			-- should I track time on fingers and clear them periodically?

			-- TODO how often to process events?
			-- if I do every event, and SDL sends n separate events for n touches, then I'll have n x processing than I need
			-- so I guess I should process multitouch in :update()
			self.gotFingerEvent = true
		elseif e.type == keyUpEventType
		or e.type == keyDownEventType
		then
			handleKeyUpDown(self, e)
		end
	end

	function cl:mouseDownEvent(dx, dy, shiftDown, guiDown, altDown, x, y)
		if dx == 0 and dy == 0 then return end
		if shiftDown then
			if self.view.ortho then
				-- ortho = shrink / grow view size
				self.view.orthoSize = self.view.orthoSize * math.exp(dy * -.03)
			else
				-- frustum = zoom dist in and out
				self.view.pos = (self.view.pos - self.view.orbit) * math.exp(dy * -.03) + self.view.orbit
			end
		elseif altDown then
			if self.view.ortho then
				-- ortho = rotate view
				-- will this be this frames delta or last frames delta, eh?
				local aspectRatio = self.width / self.height
				local rx = aspectRatio * (self.mouse.pos.x - .5) * 2
				local ry = (self.mouse.pos.y - .5) * 2
				local rx2 = aspectRatio * (x / self.width - .5) * 2
				local ry2 = ((1 - y / self.height) - .5) * 2
				local angle = math.asin((rx2 * ry - ry2 * rx) / math.sqrt((rx^2 + ry^2) * (rx2^2 + ry2^2)))
				local rotation = quatd():fromAngleAxis(0, 0, 1, math.deg(angle))
				self.view.angle = (self.view.angle * rotation):normalize()
			else
				-- frustum = move orbit center
				local dist = (self.view.pos - self.view.orbit):length()
				self.view.orbit = self.view.orbit + self.view.angle:rotate(vec3d(-dx,dy,0) * (dist / self.height))
				self.view.pos = self.view.angle:zAxis() * dist + self.view.orbit
			end
		else
			if self.view.ortho then
				-- ortho = drag
				local aspectRatio = self.width / self.height
				local fdx = -2 * dx / self.width * self.view.orthoSize * aspectRatio
				local fdy = 2 * dy / self.height * self.view.orthoSize
				self.view.pos = self.view.pos + self.view.angle:rotate(vec3d(fdx, fdy, 0))
			else
				-- frustum = rotate around orbit
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

	-- subclass so the caller doesn't override these new functions...
	return cl:subclass()
end
