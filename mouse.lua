--[[
I went and tied mouse closely with gui, then tried to separate gui from tactics ...
this might end up in openglapp ...
--]]

local ffi = require 'ffi'
local gl = require 'gl'
local sdl = require 'sdl'
local SDLApp = require 'sdl.app'
local bit = require 'bit'
local class = require 'ext.class'
local vec2i = require 'vec-ffi.vec2i'
local vec2f = require 'vec-ffi.vec2f'
local vec2d = require 'vec-ffi.vec2d'

local Mouse = class()

function Mouse:init()
	-- this is the pixel position
	-- it was integer in sdl2
	-- but it is float in sdl3
	-- sooo ...
	-- for compat reasons for now i'll store a separate 'pixelPosf' for now and convert
	-- but eventually it'll be self.pixelPos = vec2f()
	self.ipos = vec2i()
	self.pixelPosf = vec2f()	-- sdl subpixel access

	-- this is the window fractional position, as a percent of the window resolution
	self.pos = vec2d()
	self.lastPos = vec2d()
	self.deltaPos = vec2d()
	self.dz = 0

	self.leftDown = false
	self.rightDown = false
end

local viewportInt = ffi.new('GLint[4]')

-- TODO :event() instead of :update()
function Mouse:update()
	-- store last state
	self.lastPos.x = self.pos.x
	self.lastPos.y = self.pos.y

	-- update new state

	local sdlButtons
	if SDLApp.sdlMajorVersion == 2 then
		sdlButtons = sdl.SDL_GetMouseState(self.ipos.s, self.ipos.s+1)
	elseif SDLApp.sdlMajorVersion == 3 then
		sdlButtons = sdl.SDL_GetMouseState(self.pixelPosf.s, self.pixelPosf.s+1)
		-- and for compat for now, convert/store the integer pixel positions
		self.ipos.x, self.ipos.y = self.pixelPosf.x, self.pixelPosf.y
	else
		error("SDLApp.sdlMajorVersion is unknown: "..require'ext.tolua'(SDLApp.sdlMajorVersion))
	end

	-- TODO use glapp for the size, in case the viewport is set to a subset of the window
	gl.glGetIntegerv(gl.GL_VIEWPORT, viewportInt)
	local viewWidth, viewHeight = viewportInt[2], viewportInt[3]

	-- not working ... might need sdl event handling for this (i.e. openglapp)
	self.dz = 0
	-- TODO modern SDL uses SDL_MOUSEWHEEL event ...
	--if bit.band(sdlButtons, bit.lshift(1, sdl.SDL_BUTTON_WHEELUP-1)) ~= 0 then self.dz = self.dz + 1 end
	--if bit.band(sdlButtons, bit.lshift(1, sdl.SDL_BUTTON_WHEELDOWN-1)) ~= 0 then self.dz = self.dz - 1 end
	-- sdl + mouse wheel is not working:
	if self.dz ~= 0 then print('mousedz',self.dz) end

	self.pos.x = self.ipos.x / viewWidth
	self.pos.y = 1 - self.ipos.y / viewHeight

	-- TODO dz in windows should be scaled down ... alot
	self.deltaPos.x = self.pos.x - self.lastPos.x
	self.deltaPos.y = self.pos.y - self.lastPos.y

	-- rest of the story

	self.lastLeftDown = self.leftDown
	self.lastRightDown = self.rightDown
	self.leftDown = bit.band(sdlButtons, sdl.SDL_BUTTON_LMASK) ~= 0
	self.rightDown = bit.band(sdlButtons, sdl.SDL_BUTTON_RMASK) ~= 0

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
				self.leftDown = false
			end
		end

		if self.rightDown then	-- right down
			if not self.lastRightDown then	-- right press
				self.rightPress = true
				self.rightDown = true
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
				self.rightDown = false
			end
		end
	end
end

return Mouse
