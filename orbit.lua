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
		self.leftAltDown = false
		self.rightAltDown = false
	end

	function cl:event(event, eventPtr)
		local superEvent = cl.super.event
		if superEvent then
			superEvent(self, event, eventPtr)
		end

		local canHandleMouse = true
		local canHandleKeyboard = true
		if ImGuiApp and ImGuiApp.is(self) then
			local ig = require 'ffi.imgui'
			canHandleMouse = not ig.igGetIO()[0].WantCaptureMouse
			canHandleKeyboard = not ig.igGetIO()[0].WantCaptureKeyboard
		end

		local shiftDown = leftShiftDown or rightShiftDown
		local guiDown = leftGuiDown or rightGuiDown
		local altDown = leftAltDown or rightAltDown
		if event.type == sdl.SDL_MOUSEMOTION 
		or event.type == sdl.SDL_MOUSEWHEEL
		then
			if canHandleMouse then
				local dx, dy
				if event.type == sdl.SDL_MOUSEMOTION then
					dx = event.motion.xrel
					dy = event.motion.yrel
				else
					dx = 10 * event.wheel.x
					dy = 10 * event.wheel.y
				end
				if (leftButtonDown and not guiDown)
				or event.type == sdl.SDL_MOUSEWHEEL
				then
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
						self.view.orbit = self.view.orbit + self.view.angle:rotate(vec3(-dx,dy,0) * .1)
						self.view.pos = self.view.angle:zAxis() * dist + self.view.orbit
					else
						if dx ~= 0 or dy ~= 0 then
							if self.view.ortho then
								local aspectRatio = self.width / self.height
								local fdx = -2 * dx / self.width * self.view.orthoSize * aspectRatio
								local fdy = 2 * dy / self.height * self.view.orthoSize
								self.view.pos = self.view.pos + vec3(fdx, fdy, 0)
							else
								local magn = math.sqrt(dx * dx + dy * dy)
								local fdx = dx / magn
								local fdy = dy / magn
								local rotation = quat():fromAngleAxis(-fdy, -fdx, 0, magn)
								self.view.angle = (self.view.angle * rotation):normalize()
								self.view.pos = self.view.angle:zAxis() * (self.view.pos - self.view.orbit):length() + self.view.orbit
							end
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
			elseif event.key.keysym.sym == sdl.SDLK_LALT then
				leftAltDown = true
			elseif event.key.keysym.sym == sdl.SDLK_RALT then
				rightAltDown = true
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
			elseif event.key.keysym.sym == sdl.SDLK_LALT then
				leftAltDown = false
			elseif event.key.keysym.sym == sdl.SDLK_RALT then
				rightAltDown = false
			end
		end
	end

	return cl
end
