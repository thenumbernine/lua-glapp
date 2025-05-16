#!/usr/bin/env luajit
local cmdline = require 'ext.cmdline'(...)
local ffi = require 'ffi'

local sdl, SDLApp = require 'sdl.setup' (cmdline.sdl or '2')
local gl = require 'gl.setup' (cmdline.gl or 'OpenGLES3')


local Test = require 'glapp.orbit'()
Test.viewUseGLMatrixMode = true

Test.title = "Spinning Triangle"

function Test:initGL()
	print('SDL_GetVersion:', self.sdlGetVersion())
end

function Test:update()
	Test.super.update(self)

	gl.glClearColor(0, 0, 0, 0)
	gl.glClear(gl.GL_COLOR_BUFFER_BIT)

	local t = sdl.SDL_GetTicks() * 1e-3
	gl.glRotatef(t * 30, 0, 1, 0)

	gl.glBegin(gl.GL_TRIANGLES)
	gl.glColor3f(1, 0, 0)
	gl.glVertex3f(-5, -4, 0)
	gl.glColor3f(0, 1, 0)
	gl.glVertex3f(5, -4, 0)
	gl.glColor3f(0, 0, 1)
	gl.glVertex3f(0, 6, 0)
	gl.glEnd()
end

return Test():run()
