local ffi = require 'ffi'
local sdl = require 'ffi.sdl'
local bit = require 'bit'
local class = require 'ext.class'

-- [[ TODO put these in a SDL dedicated library, make them accessible to the outside world
local function sdlAssert(result)
	if result then return end
	local msg = ffi.string(sdl.SDL_GetError())
	error('SDL_GetError(): '..msg)
end

local function sdlAssertZero(intResult)
	sdlAssert(intResult == 0)
	return intResult
end

local function sdlAssertNonNull(ptrResult)
	sdlAssert(ptrResult ~= nil)
	return ptrResult
end
--]]

-- too bad for so long Windows would only ship with GL 1.1
--  has that changed?
local addWGL = ffi.os == 'Windows'

-- this has to be requestExit for all windows opengl programs, so I figure as much to do it here ...
-- that makes this piece of code not-cross-platform
-- the danger is, the whole purpose of passing gl through init args is to provide non-ffi.gl gl's (like EGL)
-- of course that was experimental to begin with
-- this code preys explicitly upon ffi.gl
local wglFuncs
if addWGL then
	local table = require 'ext.table'
	local string = require 'ext.string'

	local gl = require 'gl'	-- for GLenum's def
	wglFuncs = table()

	ffi.cdef('void* wglGetProcAddress(const char*);')
	for _,line in ipairs(string.split(string.trim(gl.code),'[\r\n]')) do
		local line = line
		local returnType, func, params, cdef
		xpcall(function()
			if line ~= '' then
				local rest = line:match'^extern%s+(.*)$'
				if rest then
					-- looks like the windows gl.h for v1.1 doesn't use 'extern' while the glext.h does
					-- and since we're fixing windows glext.h, how about we just skip the non-externs
					-- all else should be function defs
					-- lazy tokenizer:
					line = line:gsub('%*', ' * '):gsub('%s+', ' ')	-- help the lazy tokenzier parse return types
					returnType, func, params = line:match('^(.+)%s+(%S+)%s*%((.*)%);%s*$')
					wglFuncs:insert{returnType=returnType, func=func, params=params}
				end
			end
		end, function(err)
			print('line = ', line)
			print('returnType = ', returnType)
			print('func = ', func)
			print('params = ', params)
			print('cdef = ', cdef)
			io.stderr:write(err..'\n'..debug.traceback())
		end)
	end
end


--[[
parameters to override:
	width, height = window size
	title
	sdlInitFlags = init flags.  default is SDL_INIT_VIDEO
	gl
	initGL() = post-opengl init
	update() = doesn't include glClear
	event(event) = on-SDL-event callback
	exit() = shutdown
--]]
local GLApp = class()

function GLApp:init()
	self.done = false
end

function GLApp:requestExit()
	self.done = true
end

function GLApp:size()
	return self.width, self.height
end

GLApp.title = "OpenGL App"
GLApp.sdlInitFlags = sdl.SDL_INIT_VIDEO
GLApp.width = 640
GLApp.height = 480

function GLApp:run()
	sdlAssertZero(sdl.SDL_Init(self.sdlInitFlags))
	xpcall(function()
		if not self.gl then
			self.gl = require 'gl'
		end
		local gl = self.gl

		local eventPtr = ffi.new('SDL_Event[1]')

		-- [[ needed for windows, not for ... android? I forget ...
		sdlAssertZero(sdl.SDL_GL_SetAttribute(sdl.SDL_GL_RED_SIZE, 8))
		sdlAssertZero(sdl.SDL_GL_SetAttribute(sdl.SDL_GL_GREEN_SIZE, 8))
		sdlAssertZero(sdl.SDL_GL_SetAttribute(sdl.SDL_GL_BLUE_SIZE, 8))
		sdlAssertZero(sdl.SDL_GL_SetAttribute(sdl.SDL_GL_ALPHA_SIZE, 8))
		sdlAssertZero(sdl.SDL_GL_SetAttribute(sdl.SDL_GL_DEPTH_SIZE, 24))
		sdlAssertZero(sdl.SDL_GL_SetAttribute(sdl.SDL_GL_DOUBLEBUFFER, 1))
		--]]

--[[ screen
		local screenFlags = bit.bor(sdl.SDL_OPENGL, sdl.SDL_DOUBLEBUF, sdl.SDL_RESIZABLE)
		local screen = sdl.SDL_SetVideoMode(self.width, self.height, 0, screenFlags)
		sdl.SDL_WM_SetCaption(self.title, nil)
--]]
-- [[ window
		self.window = sdlAssertNonNull(sdl.SDL_CreateWindow(
			self.title,
			sdl.SDL_WINDOWPOS_CENTERED,
			sdl.SDL_WINDOWPOS_CENTERED,
			self.width, self.height,
			bit.bor(
				sdl.SDL_WINDOW_OPENGL,
				sdl.SDL_WINDOW_RESIZABLE,
				sdl.SDL_WINDOW_SHOWN)))
		self.sdlCtx = sdlAssertNonNull(sdl.SDL_GL_CreateContext(self.window))
--]]
		--sdl.SDL_EnableKeyRepeat(0,0)
		sdlAssertZero(sdl.SDL_GL_SetSwapInterval(0))

		--gl.glUseProgram(0)

		-- now that gl is loaded, if we're windows then we need to load extensions
		if addWGL then
			for _,info in ipairs(wglFuncs) do
				local func = info.func
				gl[func] = ffi.new('PFN'..func:upper()..'PROC', gl.wglGetProcAddress(func))
			end
		end
		
		sdl.SDL_SetWindowSize(self.window, self.width, self.height)
		gl.glViewport(0, 0, self.width, self.height)

		if self.initGL then self:initGL(gl, 'gl') end
	
		repeat
			while sdl.SDL_PollEvent(eventPtr) > 0 do
				if eventPtr[0].type == sdl.SDL_QUIT then
					self:requestExit()
--[[ screen
				elseif eventPtr[0].type == sdl.SDL_VIDEORESIZE then
					self.width, self.height = eventPtr[0].resize.w, eventPtr[0].resize.h
					gl.glViewport(0, 0, self.width, self.height)
--]]
-- [[ window
				elseif eventPtr[0].type == sdl.SDL_WINDOWEVENT then
					if eventPtr[0].window.event == sdl.SDL_WINDOWEVENT_SIZE_CHANGED then
						local newWidth, newHeight = eventPtr[0].window.data1, eventPtr[0].window.data2
						if self.width ~= newWidth or self.height ~= newHeight then
							self.width, self.height = newWidth, newHeight
							gl.glViewport(0, 0, self.width, self.height)
						end
					end
--]]
				elseif eventPtr[0].type == sdl.SDL_KEYDOWN then
					if ffi.os == 'Windows' and eventPtr[0].key.keysym.sym == sdl.SDLK_F4 and bit.band(eventPtr[0].key.keysym.mod, sdl.KMOD_ALT) ~= 0 then
						self:requestExit()
						break
					end
					if ffi.os == 'OSX' and eventPtr[0].key.keysym.sym == sdl.SDLK_q and bit.band(eventPtr[0].key.keysym.mod, sdl.KMOD_GUI) ~= 0 then
						self:requestExit()
						break
					end
				end
				if self.event then
					-- TODO at first i passed eventPtr[0] luajit ref for convenience
					-- but now that ImGui uses the ptr itself, I need to pass the ptr
					-- so ... eventually phase eventPtr[0] out?
					self:event(eventPtr[0], eventPtr)
				end
			end
			
			if self.update then self:update() end
		
--[[ screen
			sdl.SDL_GL_SwapBuffers()
--]]
-- [[ window
			sdl.SDL_GL_SwapWindow(self.window)
--]]
		until self.done
		
	end, function(err)
		print(err)
		print(debug.traceback())
	end)

	if self.exit then self:exit() end
	
	sdl.SDL_GL_DeleteContext(self.sdlCtx)
	sdl.SDL_DestroyWindow(self.window);
	sdl.SDL_Quit()
end

--[[
This is a common feature so I'll put it here.
It is based on Image, but I'll only require() Image within the function so GLApp itself doesn't depend on Image.
I put it here vs lua-opengl because it also depends on GLApp.width and .height, so ultimately it is dependent on GLApp.
It uses a .screenshotContext field for caching the Image buffer of the read pixels, and the buffer for flipping them before saving the screenshot.
--]]
function GLApp:screenshotToFile(filename)
	local Image = require 'image'
	local gl = self.gl
	local w, h = self.width, self.height

	self.screenshotContext = self.screenshotContext or {}
	local ssimg = self.screenshotContext.ssimg
	local ssflipped = self.screenshotContext.ssflipped
	if ssimg then
		if w ~= ssimg.width or h ~= ssimg.height then
			ssimg = nil
			ssflipped = nil
		end
	end
	-- hmm, I'm having trouble with anything but RGBA ...
	if not ssimg then
		ssimg = Image(w, h, 4, 'unsigned char')
		ssflipped = Image(w, h, 4, 'unsigned char')
		self.screenshotContext.ssimg = ssimg
		self.screenshotContext.ssflipped = ssflipped
	end
	--gl.glPixelStorei(gl.GL_UNPACK_ALIGNMENT, 1)
	gl.glReadPixels(0, 0, w, h, gl.GL_RGBA, gl.GL_UNSIGNED_BYTE, ssimg.buffer)
	ssimg:flip(ssflipped)
	-- but I don't want dest alpha, so I'll make it full here
	for i=3,4*w*h-1,4 do
		ssflippped.buffer[i] = 255
	end
	ssflipped:save(filename)
end

return GLApp
