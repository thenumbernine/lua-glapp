#!/usr/bin/env luajit
-- test but with textures
local ffi = require 'ffi'
local gl = require 'gl.setup' (... or 'OpenGLES3')
local getTime = require 'ext.timer'.getTime
local Image = require 'image'
local GLTex2D = require 'gl.tex2d'

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

	self.view.ortho = true
	self.view.orthoSize = 10

	local img = Image'src.png'
	local tex = GLTex2D{
		image = img,
		minFilter = gl.GL_NEAREST,
		magFilter = gl.GL_NEAREST,
	}:unbind()

	self.obj = require 'gl.sceneobject'{
		program = require 'gl.program'{
			version = 'latest es',
			header = 'precision highp float;',
			vertexCode = [[
in vec2 vertex;
in vec3 color;
out vec2 tcv;
out vec4 colorv;
uniform mat4 mvProjMat;
void main() {
	colorv = vec4(color, 1.);
	tcv = vertex;
	gl_Position = mvProjMat * vec4(vertex, 0., 1.);
}
]],
			fragmentCode = [[
in vec2 tcv;
in vec4 colorv;
out vec4 fragColor;
uniform sampler2D tex;
void main() {
	fragColor = colorv * texture(tex, tcv);
}
]],
			uniforms = {
				tex = 0,
			},
		},
		geometry = {
			mode = gl.GL_TRIANGLES,
			count = 3,
		},
		texs = {tex},
		attrs = {
			vertex = {
				buffer = {
					data = {
						-5, -4,
						5, -4,
						0, 6,
					},
				},
			},
			color = {
				buffer = {
					data = {
						1, 0, 0,
						0, 1, 0,
						0, 0, 1,
					},
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
