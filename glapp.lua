local ffi = require 'ffi'
local sdl = require 'sdl'
local SDLApp = require 'sdl.app'
local sdlAssertNonNull = require 'sdl.assert'.nonnull

local gl

-- Too bad for so long Windows would only ship with GL 1.1 ... has that changed?
-- In fact no, things got worse, as now Apple has thrown its hat into the ring of shoddy OpenGL support.
-- But if we go the GLEW-like route for OSX, we can do >2.1 stuff via extensions, however it still only gives us GLSL support up to 1.20 ... smh
local addGLFuncsFromGetProcAddress = ffi.os == 'Windows'
	-- or ffi.os == 'OSX' -- getting a require loop from this.  how does it work in windows but not osx?

-- this has to be requestExit for all windows opengl programs, so I figure as much to do it here ...
-- that makes this piece of code not-cross-platform
-- the danger is, the whole purpose of passing gl through init args is to provide non-ffi.gl gl's (like EGL)
-- of course that was experimental to begin with
-- this code preys explicitly upon ffi.gl
local glFuncs
if addGLFuncsFromGetProcAddress then
	local table = require 'ext.table'
	local string = require 'ext.string'

	gl = require 'gl'	-- for GLenum's def
	glFuncs = table()

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
					glFuncs:insert{returnType=returnType, func=func, params=params}
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

function GLApp:sdlGLSetAttributes()
	-- [[ needed for windows, not for ... android? I forget ...
	self.sdlAssert(sdl.SDL_GL_SetAttribute(sdl.SDL_GL_RED_SIZE, 8))
	self.sdlAssert(sdl.SDL_GL_SetAttribute(sdl.SDL_GL_GREEN_SIZE, 8))
	self.sdlAssert(sdl.SDL_GL_SetAttribute(sdl.SDL_GL_BLUE_SIZE, 8))
	self.sdlAssert(sdl.SDL_GL_SetAttribute(sdl.SDL_GL_ALPHA_SIZE, 8))
	self.sdlAssert(sdl.SDL_GL_SetAttribute(sdl.SDL_GL_DEPTH_SIZE, 24))
	self.sdlAssert(sdl.SDL_GL_SetAttribute(sdl.SDL_GL_DOUBLEBUFFER, 1))
	--]]

	-- [[ OSX wants to set GL to version 2.1 even though they claim they support up to 4.1 ...
	-- is there any way to query the highest available GL version from SDL?  Or do I just have to know that, because it's OSX, it's going to be extra-retarded?
	-- Annnd..... this gives me a black screen with no errors.
	-- Running without these gets us GL 2.1 compat
	-- Running with the context version request only still gets us 2.1
	-- Running with SDL_GL_CONTEXT_PROFILE_MASK gets us a black screen
	-- Running with *only* SDL_GL_CONTEXT_PROFILE_MASK  says I'm getting version 4.1 ... but yeah blank screen ... and glCreateShader fails for GL_VERTEX_SHADER
	-- This page: https://stackoverflow.com/questions/48714591/modern-opengl-macos-only-black-screen
	-- ... sounds like I *must* create a VAO, therefore deprecated GL 1 and GL 2 stuff doesn't work with GL core 4 ...
	-- ... which means I probably want a toggle here, for OSX: GL 2.1 or GL core 4.1 ...
	-- I want to use OpenGL 2.1 w/extensions, and get the best of old and new OpenGL
	--  however when I choose this, OSX only gives me GLSL up to 1.20 ... smh
	-- So if I want new GLSL then I am forced to use OpenGL 4.1 core ...
	if ffi.os == 'OSX' then
		-- [=[ using OSX builtin GL which is 4.1
		--local version = {2, 1}
		--local version = {3, 3}
		local version = {4, 1}		-- glGet GL_VERSION comes back 4.1
		--local version = {4, 6}
		self.sdlAssert(sdl.SDL_GL_SetAttribute(sdl.SDL_GL_CONTEXT_MAJOR_VERSION, version[1]))
		self.sdlAssert(sdl.SDL_GL_SetAttribute(sdl.SDL_GL_CONTEXT_MINOR_VERSION, version[2]))
		self.sdlAssert(sdl.SDL_GL_SetAttribute(sdl.SDL_GL_CONTEXT_PROFILE_MASK, sdl.SDL_GL_CONTEXT_PROFILE_CORE))
		self.sdlAssert(sdl.SDL_GL_SetAttribute(sdl.SDL_GL_CONTEXT_FLAGS, sdl.SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG))
		self.sdlAssert(sdl.SDL_GL_SetAttribute(sdl.SDL_GL_ACCELERATED_VISUAL, 1))
		--]=]
		--[=[ trying to get GLES3 working on OSX ... getting "SDL_GetError(): Could not initialize OpenGL / GLES library"
		-- TODO TODO TODO on OSX still haven't figured this out, even with SDL3
		sdl.SDL_SetHint("SDL_HINT_OPENGL_ES_DRIVER", "1")
		sdl.SDL_SetHint("SDL_HINT_RENDER_DRIVER", "opengles")
		sdl.SDL_SetHint("SDL_HINT_OPENGL_LIBRARY", "GLESv2")	-- need a full path here?
		sdl.SDL_SetHint("SDL_HINT_EGL_LIBRARY", "EGL")
		if self.sdlMajorVersion == 2 then	-- only for SDL2, not for SDL3
			self.sdlAssert(sdl.SDL_GL_SetAttribute(sdl.SDL_GL_CONTEXT_EGL, 1))
		end
		self.sdlAssert(sdl.SDL_GL_SetAttribute(sdl.SDL_GL_CONTEXT_PROFILE_MASK, sdl.SDL_GL_CONTEXT_PROFILE_ES))
		self.sdlAssert(sdl.SDL_GL_SetAttribute(sdl.SDL_GL_CONTEXT_MAJOR_VERSION, 3))
		self.sdlAssert(sdl.SDL_GL_SetAttribute(sdl.SDL_GL_CONTEXT_MINOR_VERSION, 0))
		--]=]
	end
	--]]
end

function GLApp:initWindow()
	self:sdlGLSetAttributes()
	GLApp.super.initWindow(self)

	self.sdlCtx = sdlAssertNonNull(sdl.SDL_GL_CreateContext(self.window))

	--sdl.SDL_EnableKeyRepeat(0,0)
	--self.sdlAssert( -- assert not really required, and it fails on raspberry pi, so ...
	sdl.SDL_GL_SetSwapInterval(0)
	--)

	-- now that gl is loaded, if we're windows then we need to load extensions
	if addGLFuncsFromGetProcAddress then
		for _,info in ipairs(glFuncs) do
			local func = info.func
			gl[func] = ffi.new('PFN'..func:upper()..'PROC', sdl.SDL_GL_GetProcAddress(func))
		end
	end

	gl = require 'gl'
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
	if self.sdlMajorVersion == 2 then
		sdl.SDL_GL_DeleteContext(self.sdlCtx)
	elseif self.sdlMajorVersion == 3 then
		sdl.SDL_GL_DestroyContext(self.sdlCtx)
	else
		error("SDLApp.sdlMajorVersion is unknown: "..require'ext.tolua'(SDLApp.sdlMajorVersion))
	end
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
