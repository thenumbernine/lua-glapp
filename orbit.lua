-- This class adds orbit trackball behavior to a GLApp (or GLApp subclass).
-- It also calls View.apply on the class if it has not yet already been applied to the class
local class = require 'ext.class'
local sdl = require 'ffi.sdl'
local vec3d = require 'vec-ffi.vec3d'
local quatd = require 'vec-ffi.quatd'
local Mouse = require 'glapp.mouse'

local result, ImGuiApp = pcall(require, 'imguiapp')
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

	function cl:event(event, eventPtr)
		local superEvent = cl.super.event
		if superEvent then
			superEvent(self, event, eventPtr)
		end

		local canHandleMouse = true
		--local canHandleKeyboard = true
		if ImGuiApp and ImGuiApp:isa(self) then
			local ig = require 'imgui'
			canHandleMouse = not ig.igGetIO()[0].WantCaptureMouse
			--canHandleKeyboard = not ig.igGetIO()[0].WantCaptureKeyboard
		end

		if self.mouse then	-- event() is called before init()
			self.mouse:update()
		end

		local shiftDown = self.leftShiftDown or self.rightShiftDown
		local guiDown = self.leftGuiDown or self.rightGuiDown
		local altDown = self.leftAltDown or self.rightAltDown
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
				if (self.mouse and self.mouse.leftDown and not guiDown)
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
						self.view.orbit = self.view.orbit + self.view.angle:rotate(vec3d(-dx,dy,0) * (dist / self.height))
						self.view.pos = self.view.angle:zAxis() * dist + self.view.orbit
					else
						if dx ~= 0 or dy ~= 0 then
							if self.view.ortho then
								local aspectRatio = self.width / self.height
								local fdx = -2 * dx / self.width * self.view.orthoSize * aspectRatio
								local fdy = 2 * dy / self.height * self.view.orthoSize
								self.view.pos = self.view.pos + vec3d(fdx, fdy, 0)
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
			end
		elseif event.type == sdl.SDL_KEYUP
		or event.type == sdl.SDL_KEYDOWN
		then
			local down = event.type == sdl.SDL_KEYDOWN
			if event.key.keysym.sym == sdl.SDLK_LSHIFT then
				self.leftShiftDown = down
			elseif event.key.keysym.sym == sdl.SDLK_RSHIFT then
				self.rightShiftDown = down
			elseif event.key.keysym.sym == sdl.SDLK_LGUI then
				self.leftGuiDown = down
			elseif event.key.keysym.sym == sdl.SDLK_RGUI then
				self.rightGuiDown = down
			elseif event.key.keysym.sym == sdl.SDLK_LALT then
				self.leftAltDown = down
			elseif event.key.keysym.sym == sdl.SDLK_RALT then
				self.rightAltDown = down
			end
		end
	end

	return cl
end
