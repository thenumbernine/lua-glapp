#!/usr/bin/env luajit
local ffi = require 'ffi'

local gl = require 'gl'
--[[ 
ubuntu 20.04 
valgrind luajit-openresty-2.1.0-beta3-debug
...finds a leak from the previous line:

==$PID== 67 bytes in 1 blocks are definitely lost in loss record 2,250 of 2,607
==$PID==    at 0x483B7F3: malloc (in /usr/lib/x86_64-linux-gnu/valgrind/vgpreload_memcheck-amd64-linux.so)
==$PID==    by 0x4018EA8: _dl_exception_create_format (dl-exception.c:146)
==$PID==    by 0x400C3B4: _dl_lookup_symbol_x (dl-lookup.c:878)
==$PID==    by 0x4B3A3DC: do_sym (dl-sym.c:158)
==$PID==    by 0x4B3A3DC: _dl_sym (dl-sym.c:274)
==$PID==    by 0x49B74A7: dlsym_doit (dlsym.c:50)
==$PID==    by 0x4B3A8B7: _dl_catch_exception (dl-error-skeleton.c:208)
==$PID==    by 0x4B3A982: _dl_catch_error (dl-error-skeleton.c:227)
==$PID==    by 0x49B7B58: _dlerror_run (dlerror.c:170)
==$PID==    by 0x49B7524: dlsym (dlsym.c:70)
==$PID==    by 0x5126C8D: ??? (in /usr/lib/x86_64-linux-gnu/libGLX.so.0.0.0)
==$PID==    by 0x510E796: ??? (in /usr/lib/x86_64-linux-gnu/libGLX.so.0.0.0)
==$PID==    by 0x4011B89: call_init.part.0 (dl-init.c:72)
--]]

local sdl = require 'ffi.sdl'

local Test = require 'glapp.orbit'()

Test.title = "Spinning Triangle"

function Test:initGL()
	local version = ffi.new'SDL_version[1]'
	sdl.SDL_GetVersion(version)
	print'SDL_GetVersion:'
	print(version[0].major..'.'..version[0].minor..'.'..version[0].patch)
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

Test():run()
