#!/usr/bin/env luajit
local ffi = require 'ffi'
local gl = require 'gl.setup' (... or 'OpenGLES3')
local getTime = require 'ext.timer'.getTime

local vertexes = ffi.new('float[9]',
	-5, -4, 0,
	5, -4, 0,
	0, 6, 0
)

local colors = ffi.new('float[9]',
	1, 0, 0,
	0, 1, 0,
	0, 0, 1
)

local Test = require 'glapp.orbit'()
Test.title = "Spinning Triangle"
Test.viewUseBuiltinMatrixMath = true		-- don't use glMatrix* calls

Test.viewDist = 20

function Test:initGL()
	local version = ffi.new'SDL_version[1]'
	local sdl = require 'ffi.req' 'sdl'
	sdl.SDL_GetVersion(version)
	print'SDL_GetVersion:'
	print(version[0].major..'.'..version[0].minor..'.'..version[0].patch)

	print('GLES Version', ffi.string(gl.glGetString(gl.GL_VERSION)))
	print('GL_SHADING_LANGUAGE_VERSION', ffi.string(gl.glGetString(gl.GL_SHADING_LANGUAGE_VERSION)))

print('glsl version', require 'gl.program'.getVersionPragma())
print('glsl es version', require 'gl.program'.getVersionPragma(true))

	-- default shader
	local glslheader = 'precision highp float;\n'

	self.shader = require 'gl.program'{
		version = 'latest es',
		vertexCode = glslheader..[[
layout(location=0) in vec2 vertex;
layout(location=1) in vec4 color;
out vec4 colorv;
uniform mat4 mvProjMat;
void main() {
	colorv = color;
	gl_Position = mvProjMat * vec4(vertex, 0., 1.);
}
]],
		fragmentCode = glslheader..[[
in vec4 colorv;
out vec4 fragColor;
void main() {
	fragColor = colorv;
}
]],
		}

	self.view.ortho = true
	self.view.orthoSize = 10
end

function Test:update()
	Test.super.update(self)

	gl.glClearColor(0, 0, 0, 0)
	gl.glClear(gl.GL_COLOR_BUFFER_BIT)

	local t = getTime()
	self.view.mvMat:applyRotate(math.rad(t * 30), 0, 1, 0)
	self.view.mvProjMat:mul4x4(self.view.projMat, self.view.mvMat)

	self.shader:use()
		:setUniform('mvProjMat', self.view.mvProjMat.ptr)

	gl.glVertexAttribPointer(0, 3, gl.GL_FLOAT, gl.GL_FALSE, 0, vertexes)
	gl.glVertexAttribPointer(1, 3, gl.GL_FLOAT, gl.GL_FALSE, 0, colors)
	gl.glEnableVertexAttribArray(0)
	gl.glEnableVertexAttribArray(1)
	gl.glDrawArrays(gl.GL_TRIANGLES, 0, 3)
	gl.glDisableVertexAttribArray(0)
	gl.glDisableVertexAttribArray(1)

	self.shader:useNone()
end

return Test():run()
