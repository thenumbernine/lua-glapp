#!/usr/bin/env luajit
local ffi = require 'ffi'
local gl = require 'gl'
local sdl = require 'ffi.sdl'

local Test = require 'glapp.orbit'()

Test.title = "Spinning Triangle"

function Test:initGL()
	--[[ present in 1.3.0, which is what Malkia's UFO uses
	local version = sdl.SDL_Linked_Version()
	print'SDL_Linked_Version:'
	print(version[0].major..'.'..version[0].minor..'.'..version[0].patch)
	--]]
	local version = ffi.new'SDL_version[1]'
	sdl.SDL_GetVersion(version)
	print'SDL_GetVersion:'
	print(version[0].major..'.'..version[0].minor..'.'..version[0].patch)
end

function Test:update()
	Test.super.update(self)
	
	gl.glClearColor(0, 0, 0, 0)
	gl.glClear(gl.GL_COLOR_BUFFER_BIT)

	local t = sdl.SDL_GetTicks() / 1000	-- gettime?
	gl.glRotatef(.3 * t * 100, 0, 1, 0)
	
	gl.glBegin(gl.GL_TRIANGLES)
	gl.glColor3f(1, 0, 0)
	gl.glVertex3f(-5, -4, 0)
	gl.glColor3f(0, 1, 0)
	gl.glVertex3f(5, -4, 0)
	gl.glColor3f(0, 0, 1)
	gl.glVertex3f(0, 6, 0)
	gl.glEnd()
end

Test():run()
