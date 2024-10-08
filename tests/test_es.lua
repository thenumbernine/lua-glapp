#!/usr/bin/env luajit
-- ES test using gl.sceneobject and objects ...
local ffi = require 'ffi'
local gl = require 'gl.setup' (... or 'OpenGLES3')
local getTime = require 'ext.timer'.getTime

local Test = require 'glapp.orbit'()
Test.title = "Spinning Triangle"

Test.viewDist = 20

function Test:initGL()
	local version = ffi.new'SDL_version[1]'
	local sdl = require 'ffi.req' 'sdl'
	sdl.SDL_GetVersion(version)
	print'SDL_GetVersion:'
	print(version[0].major..'.'..version[0].minor..'.'..version[0].patch)
	
	local glGlobal = require 'gl.global'
	print('GL_VERSION', glGlobal:get'GL_VERSION')
	print('GL_SHADING_LANGUAGE_VERSION', glGlobal:get'GL_SHADING_LANGUAGE_VERSION')
	print('glsl version', require 'gl.program'.getVersionPragma(false))
	print('glsl es version', require 'gl.program'.getVersionPragma(true))

	self.view.ortho = true
	self.view.orthoSize = 10

	self.obj = require 'gl.sceneobject'{
		program = {
			version = 'latest',
			precision = 'best',
			vertexCode = [[
in vec2 vertex;
in vec3 color;
out vec4 colorv;
uniform mat4 mvProjMat;
void main() {
	colorv = vec4(color, 1.);
	gl_Position = mvProjMat * vec4(vertex, 0., 1.);
}
]],
			fragmentCode = [[
in vec4 colorv;
out vec4 fragColor;
void main() {
	fragColor = colorv;
}
]],
		},
		vertexes = {
			data = {
				-5, -4,
				5, -4,
				0, 6,
			},
			dim = 2,
		},
		geometry = {
			mode = gl.GL_TRIANGLES,
		},
		attrs = {
			color = {
				buffer = {
					data = {
						1, 0, 0,
						0, 1, 0,
						0, 0, 1,
					},
					dim = 3,
				},
			},
		},
	}

	gl.glClearColor(0, 0, 0, 1)
end

function Test:update()
	Test.super.update(self)
	gl.glClear(gl.GL_COLOR_BUFFER_BIT)

	local t = getTime()
	self.view.mvMat:applyRotate(math.rad(t * 30), 0, 1, 0)
	self.view.mvProjMat:mul4x4(self.view.projMat, self.view.mvMat)

	self.obj.uniforms.mvProjMat = self.view.mvProjMat.ptr
	self.obj:draw()
end

return Test():run()
