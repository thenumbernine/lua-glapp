#!/usr/bin/env luajit
local ffi = require 'ffi'
local GLApp = require 'glapp'
local gl = require 'ffi.OpenGL'
local glu = require 'ffi.glu'
local sdl = require 'ffi.sdl'
local class = require 'ext.class'
local table = require 'ext.table'

local Test = class(GLApp)

Test.title = "Spinning Triangle"

local x, y = ffi.new('int[1]'), ffi.new('int[1]')
function Test:update()
	local t = sdl.SDL_GetTicks() / 1000	-- gettime?
	sdl.SDL_GetMouseState(x, y)
	
	gl.glViewport(0, 0, self.width, self.height)
	
	gl.glClearColor(0, 0, 0, 0)
	gl.glClear(gl.GL_COLOR_BUFFER_BIT)
	
	gl.glMatrixMode(gl.GL_PROJECTION)
	gl.glLoadIdentity()
	glu.gluPerspective(65, self.width / self.height, 1, 100)
	
	gl.glMatrixMode(gl.GL_MODELVIEW)
	gl.glLoadIdentity()
	glu.gluLookAt(0,1,0,	0,20,0, 0,0,1)
				
	gl.glTranslatef(0, 14, 0)
	gl.glRotatef(.3 * x[0] + t * 100, 0, 0, 1)
	gl.glBegin(gl.GL_TRIANGLES)
	gl.glColor3f( 1.0, 0.0, 0.0 )
	gl.glVertex3f( -5.0, 0.0, -4.0 )
	gl.glColor3f( 0.0, 1.0, 0.0 )
	gl.glVertex3f( 5.0, 0.0, -4.0 )
	gl.glColor3f( 0.0, 0.0, 1.0 )
	gl.glVertex3f( 0.0, 0.0, 6.0 )
	gl.glEnd()
end

Test():run()
