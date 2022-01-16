#!/usr/bin/env luajit
require 'ext'
local ffi = require 'ffi'
local gl = require 'ffi.OpenGL'
class(require 'glapp', {
	initGL = function(self)
		for _,field in ipairs{
			'GL_VENDOR',
			'GL_RENDERER',
			'GL_VERSION',
		} do
			print(field, ffi.string(gl.glGetString(gl[field])))
		end
		print('GL_EXTENSIONS', '\n\t'..(ffi.string(gl.glGetString(gl.GL_EXTENSIONS)):trim():split' ':sort():concat'\n\t') )
		self.done = true
	end,
})():run()
