--[[
I went and tied mouse closely with gui, then tried to separate gui from tactics ...
this might end up in openglapp ...
--]]

local ffi = require 'ffi'
local table = require 'ext.table'
local class = require 'ext.class'
local vec2f = require 'vec-ffi.vec2f'
local sdl = require 'sdl'
local SDLApp = require 'sdl.app'


local fingerUpEventType
local fingerDownEventType
local fingerMotionEventType
local mouseButtonUpType
local mouseButtonDownType
local mouseMotionEventType
local mouseWheelEventType
if SDLApp.sdlMajorVersion == 2 then
	mouseButtonUpType = sdl.SDL_MOUSEBUTTONUP
	mouseButtonDownType = sdl.SDL_MOUSEBUTTONDOWN
	mouseMotionEventType = sdl.SDL_MOUSEMOTION
	mouseWheelEventType = sdl.SDL_MOUSEWHEEL
elseif SDLApp.sdlMajorVersion == 3 then
	mouseButtonUpType = sdl.SDL_EVENT_MOUSE_BUTTON_UP
	mouseButtonDownType = sdl.SDL_EVENT_MOUSE_BUTTON_DOWN
	mouseMotionEventType = sdl.SDL_EVENT_MOUSE_MOTION
	mouseWheelEventType = sdl.SDL_EVENT_MOUSE_WHEEL
	fingerUpEventType = sdl.SDL_EVENT_FINGER_UP
	fingerDownEventType = sdl.SDL_EVENT_FINGER_DOWN
	fingerMotionEventType = sdl.SDL_EVENT_FINGER_MOTION
end

local Mouse = class()

--[[
args:
	app = obj has .width and .height for tracking screensize
--]]
function Mouse:init(args)
	self.app = args.app

	-- state being gathered from events:

	self.newWheelDelta = vec2f()
	self.newPixelPos = vec2f()	-- pixel position, unflipped. sdl subpixel access
	self.newLeftDown = false
	self.newRightDown = false

	-- "current" state as of mouse update

	self.pos = vec2f()		-- this is the window fractional position, as a percent of the window resolution
	self.wheelDelta = vec2f()
	self.leftDown = false
	self.rightDown = false

	-- "last" state as of mouse update

	self.lastPos = vec2f()
	self.deltaPos = vec2f()

	self.fingerPinchDelta = 0
	self.activeFingers = {}
	self.activeFingersInOrder = table()
end

-- process this-frame vs last-frame state-changes
-- do this last, so that your update loop is ...
--  SDL events -> get new mouse state
--  App:update -> handle last vew new mouse staet
--  Mouse:update -> save new-to-last mouse states
function Mouse:update()
	local app = self.app

	-- process multi-finger events:
	self.doingMultiTouchGesture = nil
	self.fingerPinchDelta = 0
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

			-- tell our mouse event handler to ignore events coming from touches
			self.doingMultiTouchGesture = true
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
			self.fingerPinchDelta = zoomChange
		end
		self.lastMultiTouchDistSq = self.multiTouchDistSq
		self.gotFingerEvent = nil
	end


	-- mouse

	self.wheelDelta.x = self.newWheelDelta.x
	self.wheelDelta.y = self.newWheelDelta.y
	self.newWheelDelta.x = 0
	self.newWheelDelta.y = 0

	self.lastPos.x = self.pos.x
	self.lastPos.y = self.pos.y
	self.pos.x = tonumber(self.newPixelPos.x) / tonumber(app.width)
	self.pos.y = tonumber(self.newPixelPos.y) / tonumber(app.height)
	self.deltaPos.x = self.pos.x - self.lastPos.x
	self.deltaPos.y = self.pos.y - self.lastPos.y


	self.lastLeftDown = self.leftDown
	self.lastRightDown = self.rightDown
	self.leftDown = self.newLeftDown
	self.rightDown = self.newRightDown
--print(self.leftDown, self.rightDown)

	-- immediate frame states
	self.leftClick = false
	self.rightClick = false
	self.leftPress = false
	self.leftRelease = false
	self.rightPress = false
	self.rightRelease = false
	self.leftDragging = false
	self.rightDragging = false

	do	-- TODO used to not happen if the gui got input
		if self.leftDown then
			if not self.lastLeftDown then
				self.leftPress = true
				self.leftDragged = false
			else
				if self.deltaPos.x ~= 0 or self.deltaPos.y ~= 0 then
					self.leftDragging = true
					self.leftDragged = true
				end
			end
		else		-- left up
			if self.lastLeftDown
			and not self.leftDown			-- mouse recorded the leftdown ... to make sure we didnt mousedown on gui and then drag out
			then
				self.leftRelease = true
				if not self.leftDragged then	-- left click -- TODO - a millisecond test?
					self.leftClick = true
				end
				self.leftDragged = false
				--self.leftDown = false
			end
		end

		if self.rightDown then	-- right down
			if not self.lastRightDown then	-- right press
				self.rightPress = true
				--self.rightDown = true
				self.rightDragged = false
			else
				if self.deltaPos.x ~= 0 or self.deltaPos.y ~= 0 then
					self.rightDragging = true
					self.rightDragged = true
				end
			end
		else		-- right up
			if self.lastRightDown
			and not self.rightDown			-- mouse recorded the rightdown ... to make sure we didnt mousedown on gui and then drag out
			then
				self.rightRelease = true
				if not self.rightDragged then	-- right click -- TODO - a millisecond test?
					self.rightClick = true
				end
				self.rightDragged = false
				--self.rightDown = false
			end
		end
	end
end

function Mouse:event(e)
	if e.type == mouseButtonUpType
	or e.type == mouseButtonDownType
	then
		local down = e.type == mouseButtonDownType
		if e.button.button == sdl.SDL_BUTTON_LEFT then
			self.newLeftDown = down
		elseif e.button.button == sdl.SDL_BUTTON_RIGHT then
			self.newRightDown = down
		end
	elseif e.type == mouseMotionEventType then
		-- if it's a mouse event
		-- and it came from a touch event
		-- but we're doing a multi-touch gesture
		-- then skip processing the mouse event
		if not (
			self.doingMultiTouchGesture
			and e.motion.which == sdl.SDL_TOUCH_MOUSEID
		) then
			self.newPixelPos.x = e.motion.x
			self.newPixelPos.y = e.motion.y
		end
	elseif e.type == mouseWheelEventType then
		self.newWheelDelta.x = self.newWheelDelta.x + e.wheel.x
		self.newWheelDelta.y = self.newWheelDelta.y + e.wheel.y
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
	end
end

return Mouse
