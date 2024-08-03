local ffi = require 'ffi'
local sdl = require 'ffi.req' 'sdl'
local SDLApp = require 'sdlapp'
local sdlAssertZero = require 'sdlapp.assert'.zero
local sdlAssertNonNull = require 'sdlapp.assert'.nonnull

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
		local returnType, func, params
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
			io.stderr:write(err..'\n'..debug.traceback())
		end)
	end
end


local GLApp = SDLApp:subclass()

GLApp.title = "OpenGL App"

GLApp.sdlCreateWindowFlags = bit.bor(GLApp.sdlCreateWindowFlags, sdl.SDL_WINDOW_OPENGL)

function GLApp:initWindow()
	-- [[ needed for windows, not for ... android? I forget ...
	sdlAssertZero(sdl.SDL_GL_SetAttribute(sdl.SDL_GL_RED_SIZE, 8))
	sdlAssertZero(sdl.SDL_GL_SetAttribute(sdl.SDL_GL_GREEN_SIZE, 8))
	sdlAssertZero(sdl.SDL_GL_SetAttribute(sdl.SDL_GL_BLUE_SIZE, 8))
	sdlAssertZero(sdl.SDL_GL_SetAttribute(sdl.SDL_GL_ALPHA_SIZE, 8))
	sdlAssertZero(sdl.SDL_GL_SetAttribute(sdl.SDL_GL_DEPTH_SIZE, 24))
	sdlAssertZero(sdl.SDL_GL_SetAttribute(sdl.SDL_GL_DOUBLEBUFFER, 1))
	--]]

	GLApp.super.initWindow(self)

	self.sdlCtx = sdlAssertNonNull(sdl.SDL_GL_CreateContext(self.window))

	--sdl.SDL_EnableKeyRepeat(0,0)
	--sdlAssertZero( -- assert not really required, and it fails on raspberry pi, so ...
	sdl.SDL_GL_SetSwapInterval(0)
	--)

	-- now that gl is loaded, if we're windows then we need to load extensions
	if addWGL then
		for _,info in ipairs(wglFuncs) do
			local func = info.func
			gl[func] = ffi.new('PFN'..func:upper()..'PROC', gl.wglGetProcAddress(func))
		end
	end

	if self.initGL then self:initGL() end
end

function GLApp:resize()
	gl.glViewport(0, 0, self.width, self.height)
end

function GLApp:postUpdate()
--[[ screen
	sdl.SDL_GL_SwapBuffers()
--]]
-- [[ window
	sdl.SDL_GL_SwapWindow(self.window)
--]]
end

function GLApp:exit()
	sdl.SDL_GL_DeleteContext(self.sdlCtx)

	GLApp.super.exit(self)
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
		ssimg = Image(w, h, 3, 'unsigned char')
		ssflipped = Image(w, h, 3, 'unsigned char')
		self.screenshotContext.ssimg = ssimg
		self.screenshotContext.ssflipped = ssflipped
	end
	local push = ffi.new('GLint[1]', 0)
	gl.glGetIntegerv(gl.GL_PACK_ALIGNMENT, push)
	gl.glPixelStorei(gl.GL_PACK_ALIGNMENT, 1)	-- PACK_ALIGNMENT is for glReadPixels
	gl.glReadPixels(0, 0, w, h, gl.GL_RGB, gl.GL_UNSIGNED_BYTE, ssimg.buffer)
	gl.glPixelStorei(gl.GL_PACK_ALIGNMENT, push[0])
	ssimg:flip(ssflipped)
	ssflipped:save(filename)
end

return GLApp
