local ffi = require 'ffi'
local sdl = require 'ffi.sdl'
local bit = require 'bit'
local class = require 'ext.class'

-- too bad for so long Windows would only ship with GL 1.1
--  has that changed?
local addWGL = ffi.os == 'Windows'

-- this has to be done for all windows opengl programs, so I figure as much to do it here ...
-- that makes this piece of code not-cross-platform
-- the danger is, the whole purpose of passing gl through init args is to provide non-ffi.gl gl's (like EGL)
-- of course that was experimental to begin with
-- this code preys explicitly upon ffi.gl
local wglFuncs
if addWGL then
	require 'ext'
-- allow overwritings
	local oldgl = require 'ffi.OpenGL'
	local gl = setmetatable({}, {__index=oldgl})
	package.loaded['ffi.OpenGL'] = gl

	wglFuncs = {}
-- TODO separate this from ffi.gl?
	local wglDefs = [[
void glActiveTexture (GLenum);
void glClientActiveTexture (GLenum);
void glMultiTexCoord1d (GLenum, GLdouble);
void glMultiTexCoord1dv (GLenum, const GLdouble *);
void glMultiTexCoord1f (GLenum, GLfloat);
void glMultiTexCoord1fv (GLenum, const GLfloat *);
void glMultiTexCoord1i (GLenum, GLint);
void glMultiTexCoord1iv (GLenum, const GLint *);
void glMultiTexCoord1s (GLenum, GLshort);
void glMultiTexCoord1sv (GLenum, const GLshort *);
void glMultiTexCoord2d (GLenum, GLdouble, GLdouble);
void glMultiTexCoord2dv (GLenum, const GLdouble *);
void glMultiTexCoord2f (GLenum, GLfloat, GLfloat);
void glMultiTexCoord2fv (GLenum, const GLfloat *);
void glMultiTexCoord2i (GLenum, GLint, GLint);
void glMultiTexCoord2iv (GLenum, const GLint *);
void glMultiTexCoord2s (GLenum, GLshort, GLshort);
void glMultiTexCoord2sv (GLenum, const GLshort *);
void glMultiTexCoord3d (GLenum, GLdouble, GLdouble, GLdouble);
void glMultiTexCoord3dv (GLenum, const GLdouble *);
void glMultiTexCoord3f (GLenum, GLfloat, GLfloat, GLfloat);
void glMultiTexCoord3fv (GLenum, const GLfloat *);
void glMultiTexCoord3i (GLenum, GLint, GLint, GLint);
void glMultiTexCoord3iv (GLenum, const GLint *);
void glMultiTexCoord3s (GLenum, GLshort, GLshort, GLshort);
void glMultiTexCoord3sv (GLenum, const GLshort *);
void glMultiTexCoord4d (GLenum, GLdouble, GLdouble, GLdouble, GLdouble);
void glMultiTexCoord4dv (GLenum, const GLdouble *);
void glMultiTexCoord4f (GLenum, GLfloat, GLfloat, GLfloat, GLfloat);
void glMultiTexCoord4fv (GLenum, const GLfloat *);
void glMultiTexCoord4i (GLenum, GLint, GLint, GLint, GLint);
void glMultiTexCoord4iv (GLenum, const GLint *);
void glMultiTexCoord4s (GLenum, GLshort, GLshort, GLshort, GLshort);
void glMultiTexCoord4sv (GLenum, const GLshort *);
void glLoadTransposeMatrixf (const GLfloat *);
void glLoadTransposeMatrixd (const GLdouble *);
void glMultTransposeMatrixf (const GLfloat *);
void glMultTransposeMatrixd (const GLdouble *);
void glSampleCoverage (GLclampf, GLboolean);
void glCompressedTexImage3D (GLenum, GLint, GLenum, GLsizei, GLsizei, GLsizei, GLint, GLsizei, const GLvoid *);
void glCompressedTexImage2D (GLenum, GLint, GLenum, GLsizei, GLsizei, GLint, GLsizei, const GLvoid *);
void glCompressedTexImage1D (GLenum, GLint, GLenum, GLsizei, GLint, GLsizei, const GLvoid *);
void glCompressedTexSubImage3D (GLenum, GLint, GLint, GLint, GLint, GLsizei, GLsizei, GLsizei, GLenum, GLsizei, const GLvoid *);
void glCompressedTexSubImage2D (GLenum, GLint, GLint, GLint, GLsizei, GLsizei, GLenum, GLsizei, const GLvoid *);
void glCompressedTexSubImage1D (GLenum, GLint, GLint, GLsizei, GLenum, GLsizei, const GLvoid *);
void glGetCompressedTexImage (GLenum, GLint, void *);

void glTexImage3D (GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLsizei depth, GLint border, GLenum format, GLenum type, const GLvoid *pixels);

void glDeleteShader (GLuint shader);
void glDetachShader (GLuint program, GLuint shader);
GLuint glCreateShader (GLenum type);
void glShaderSource (GLuint shader, GLsizei count, const GLchar* *string, const GLint *length);
void glCompileShader (GLuint shader);
GLuint glCreateProgram (void);
void glAttachShader (GLuint program, GLuint shader);
void glLinkProgram (GLuint program);
void glUseProgram (GLuint program);
void glDeleteProgram (GLuint program);
void glValidateProgram (GLuint program);
void glUniform1f (GLint location, GLfloat v0);
void glUniform2f (GLint location, GLfloat v0, GLfloat v1);
void glUniform3f (GLint location, GLfloat v0, GLfloat v1, GLfloat v2);
void glUniform4f (GLint location, GLfloat v0, GLfloat v1, GLfloat v2, GLfloat v3);
void glUniform1i (GLint location, GLint v0);
void glUniform2i (GLint location, GLint v0, GLint v1);
void glUniform3i (GLint location, GLint v0, GLint v1, GLint v2);
void glUniform4i (GLint location, GLint v0, GLint v1, GLint v2, GLint v3);
void glUniform1fv (GLint location, GLsizei count, const GLfloat *value);
void glUniform2fv (GLint location, GLsizei count, const GLfloat *value);
void glUniform3fv (GLint location, GLsizei count, const GLfloat *value);
void glUniform4fv (GLint location, GLsizei count, const GLfloat *value);
void glUniform1iv (GLint location, GLsizei count, const GLint *value);
void glUniform2iv (GLint location, GLsizei count, const GLint *value);
void glUniform3iv (GLint location, GLsizei count, const GLint *value);
void glUniform4iv (GLint location, GLsizei count, const GLint *value);
void glUniformMatrix2fv (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
void glUniformMatrix3fv (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
void glUniformMatrix4fv (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
GLboolean glIsShader (GLuint shader);
GLboolean glIsProgram (GLuint program);
void glGetShaderiv (GLuint shader, GLenum pname, GLint *params);
void glGetProgramiv (GLuint program, GLenum pname, GLint *params);
void glGetAttachedShaders (GLuint program, GLsizei maxCount, GLsizei *count, GLuint *shaders);
void glGetShaderInfoLog (GLuint shader, GLsizei bufSize, GLsizei *length, GLchar *infoLog);
void glGetProgramInfoLog (GLuint program, GLsizei bufSize, GLsizei *length, GLchar *infoLog);
GLint glGetUniformLocation (GLuint program, const GLchar *name);
void glGetActiveUniform (GLuint program, GLuint index, GLsizei bufSize, GLsizei *length, GLint *size, GLenum *type, GLchar *name);
void glGetUniformfv (GLuint program, GLint location, GLfloat *params);
void glGetUniformiv (GLuint program, GLint location, GLint *params);
void glGetShaderSource (GLuint shader, GLsizei bufSize, GLsizei *length, GLchar *source);
void glBindAttribLocation (GLuint program, GLuint index, const GLchar *name);
void glGetActiveAttrib (GLuint program, GLuint index, GLsizei bufSize, GLsizei *length, GLint *size, GLenum *type, GLchar *name);
GLint glGetAttribLocation (GLuint program, const GLchar *name);

GLboolean glIsRenderbuffer (GLuint);
void glBindRenderbuffer (GLenum, GLuint);
void glDeleteRenderbuffers (GLsizei, const GLuint *);
void glGenRenderbuffers (GLsizei, GLuint *);
void glRenderbufferStorage (GLenum, GLenum, GLsizei, GLsizei);
void glGetRenderbufferParameteriv (GLenum, GLenum, GLint *);
GLboolean glIsFramebuffer (GLuint);
void glBindFramebuffer (GLenum, GLuint);
void glDeleteFramebuffers (GLsizei, const GLuint *);
void glGenFramebuffers (GLsizei, GLuint *);
GLenum glCheckFramebufferStatus (GLenum);
void glFramebufferTexture1D (GLenum, GLenum, GLenum, GLuint, GLint);
void glFramebufferTexture2D (GLenum, GLenum, GLenum, GLuint, GLint);
void glFramebufferTexture3D (GLenum, GLenum, GLenum, GLuint, GLint, GLint);
void glFramebufferRenderbuffer (GLenum, GLenum, GLenum, GLuint);
void glGetFramebufferAttachmentParameteriv (GLenum, GLenum, GLenum, GLint *);
void glGenerateMipmap (GLenum);
void glBlitFramebuffer (GLint, GLint, GLint, GLint, GLint, GLint, GLint, GLint, GLbitfield, GLenum);
void glRenderbufferStorageMultisample (GLenum, GLsizei, GLenum, GLsizei, GLsizei);
void glFramebufferTextureLayer (GLenum, GLenum, GLuint, GLint, GLint);

]]
	ffi.cdef('void* wglGetProcAddress(const char*);')
	for _,line in ipairs(wglDefs:trim():split('[\r\n]')) do
		line = line:trim()
		if line ~= '' then
			local returnType, func, params = line:match('(%w+)%s+(%w+)%s*%((.*)%);%s*')
			wglFuncs[func] = {returnType, params}
			local cdef = 'typedef '..returnType..' (*p'..func..')('..params..');'
			ffi.cdef(cdef)
		end
	end
--[[
	glShaderSource = {'GLvoid', 'GLuint shader, GLsizei count, const GLchar* *string, const GLint *length'},
	glCreateShader = {'GLuint', 'GLenum'},
--]]
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

function GLApp:done()
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
	assert(sdl.SDL_Init(self.sdlInitFlags) == 0)
	xpcall(function()		
		if not self.gl then
			self.gl = require 'ffi.OpenGL'
		end
		local gl = self.gl

		local eventPtr = ffi.new('SDL_Event[1]')

		-- [[	needed for windows, not for ... android? I forget ...
		sdl.SDL_GL_SetAttribute(sdl.SDL_GL_RED_SIZE, 8)
		sdl.SDL_GL_SetAttribute(sdl.SDL_GL_GREEN_SIZE, 8)
		sdl.SDL_GL_SetAttribute(sdl.SDL_GL_BLUE_SIZE, 8)
		sdl.SDL_GL_SetAttribute(sdl.SDL_GL_ALPHA_SIZE, 8)
		sdl.SDL_GL_SetAttribute(sdl.SDL_GL_DEPTH_SIZE, 16)
		sdl.SDL_GL_SetAttribute(sdl.SDL_GL_DOUBLEBUFFER, 1)
		--]]

		local screenFlags = bit.bor(sdl.SDL_OPENGL, sdl.SDL_DOUBLEBUF)
		-- bad on osx ...
		screenFlags = bit.bor(screenFlags, sdl.SDL_RESIZABLE)
		
		local screen = sdl.SDL_SetVideoMode(self.width, self.height, 0, screenFlags)
		sdl.SDL_WM_SetCaption(self.title, nil)
		--sdl.SDL_EnableKeyRepeat(0,0)
		
		sdl.SDL_GL_SetSwapInterval(1)

		gl.glViewport(0, 0, self.width, self.height)
		--gl.glUseProgramObjectARB(nil)

		-- now that gl is loaded, if we're windows then we need to load extensions
		if addWGL then
			for func,_ in pairs(wglFuncs) do
				gl[func] = ffi.new('p'..func, gl.wglGetProcAddress(func))
			end
		end

		if self.initGL then self:initGL(gl, 'gl') end
		
		repeat
			while sdl.SDL_PollEvent(eventPtr) > 0 do
				if eventPtr[0].type == sdl.SDL_QUIT then
					done = true
				elseif eventPtr[0].type == sdl.SDL_VIDEORESIZE then
					self.width, self.height = eventPtr[0].resize.w, eventPtr[0].resize.h
--[[ opengl resize is buggy on osx
					screen = sdl.SDL_SetVideoMode(eventPtr[0].resize.w, eventPtr[0].resize.h, 32, bit.bor(sdl.SDL_HWSURFACE, sdl.SDL_RESIZABLE))
--]]
					gl.glViewport(0, 0, self.width, self.height)
				elseif eventPtr[0].type == sdl.SDL_KEYDOWN then
					if ffi.os == 'Windows' and eventPtr[0].key.keysym.sym == sdl.SDLK_F4 and bit.band(eventPtr[0].key.keysym.mod, sdl.KMOD_ALT) ~= 0 then
						done = true
						break
					end
					if ffi.os == 'OSX' and eventPtr[0].key.keysym.sym == sdl.SDLK_q and bit.band(eventPtr[0].key.keysym.mod, sdl.KMOD_GUI) ~= 0 then
						done = true
						break
					end
				end
				if self.event then self:event(eventPtr[0]) end
			end
			
			if self.update then self:update() end
			
			sdl.SDL_GL_SwapBuffers()
		until done
		
	end, function(err)
		print(err)
		print(debug.traceback())
	end)

	if self.exit then self:exit() end
	sdl.SDL_Quit()
end

return GLApp
