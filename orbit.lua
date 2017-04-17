-- adds orbit trackball behavior to a GLApp
-- depends on View.apply
local class = require 'ext.class'
local sdl = require 'ffi.sdl'
local quat = require 'vec.quat'

local result, ImGuiApp = pcall(require, 'imguiapp')
ImGuiApp = result and ImGuiApp

return function(cl)
	cl = class(cl)

	function cl:init(...)
		cl.super.init(self, ...)
		self.leftButtonDown = false
		self.rightButtonDown = false
		self.leftShiftDown = false
		self.rightShiftDown = false
		self.leftGuiDown = false
		self.rightGuiDown = false
	end

	function cl:event(event, eventPtr)
		cl.super.event(self, event, eventPtr)
		
		local canHandleMouse = true
		local canHandleKeyboard = true
		if ImGuiApp and ImGuiApp.is(self) then
			local ig = require 'ffi.imgui'
			canHandleMouse = not ig.igGetIO()[0].WantCaptureMouse
			canHandleKeyboard = not ig.igGetIO()[0].WantCaptureKeyboard
		end

		local shiftDown = leftShiftDown or rightShiftDown
		local guiDown = leftGuiDown or rightGuiDown
		if event.type == sdl.SDL_MOUSEMOTION then
			if canHandleMouse then
				local dx = event.motion.xrel
				local dy = event.motion.yrel
				if leftButtonDown and not guiDown then
					if shiftDown then
						if dx ~= 0 or dy ~= 0 then
							self.view.pos = self.view.pos * math.exp(dy * -.03)
						end
					else
						if dx ~= 0 or dy ~= 0 then
							local magn = math.sqrt(dx * dx + dy * dy)
							local fdx = dx / magn
							local fdy = dy / magn
							local rotation = quat():fromAngleAxis(-fdy, -fdx, 0, magn)
							self.view.angle = (self.view.angle * rotation):normalize()
							self.view.pos = self.view.angle:zAxis() * self.view.pos:length()
						end
					end
				end
			end
		elseif event.type == sdl.SDL_MOUSEBUTTONDOWN then
			if event.button.button == sdl.SDL_BUTTON_LEFT then
				leftButtonDown = true
			elseif event.button.button == sdl.SDL_BUTTON_RIGHT then
				rightButtonDown = true
			end
		elseif event.type == sdl.SDL_MOUSEBUTTONUP then
			if event.button.button == sdl.SDL_BUTTON_LEFT then
				leftButtonDown = false
			elseif event.button.button == sdl.SDL_BUTTON_RIGHT then
				rightButtonDown = false
			end
		elseif event.type == sdl.SDL_KEYDOWN then
			if event.key.keysym.sym == sdl.SDLK_LSHIFT then
				leftShiftDown = true
			elseif event.key.keysym.sym == sdl.SDLK_RSHIFT then
				rightShiftDown = true
			elseif event.key.keysym.sym == sdl.SDLK_LGUI then
				leftGuiDown = true
			elseif event.key.keysym.sym == sdl.SDLK_RGUI then
				rightGuiDown = true
			end
		elseif event.type == sdl.SDL_KEYUP then
			if event.key.keysym.sym == sdl.SDLK_LSHIFT then
				leftShiftDown = false
			elseif event.key.keysym.sym == sdl.SDLK_RSHIFT then
				rightShiftDown = false
			elseif event.key.keysym.sym == sdl.SDLK_LGUI then
				leftGuiDown = false
			elseif event.key.keysym.sym == sdl.SDLK_RGUI then
				rightGuiDown = false
			end
		end
	end

	return cl
end
