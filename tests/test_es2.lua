#!/usr/bin/env luajit
-- ES test using raw gl calls
local ffi = require 'ffi'
local gl = require 'gl.setup' (... or 'OpenGLES3')
local getTime = require 'ext.timer'.getTime

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

	self.program = require 'gl.program'{
		version = 'latest es',
		header = 'precision highp float;',
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
	}

	self.geometry = require 'gl.geometry'{
		mode = gl.GL_TRIANGLES,
		count = 3,
	}

	self.vertexData = ffi.new('float[6]',
		-5, -4,
		5, -4,
		0, 6
	)
	assert(ffi.sizeof(self.vertexData) == 6 * 4)

	self.vertexBuffer = require 'gl.arraybuffer'{
		data = self.vertexData,
		size = ffi.sizeof(self.vertexData),
	}

	self.colorData = ffi.new('float[9]', 
		1, 0, 0,
		0, 1, 0,
		0, 0, 1
	)
	assert(ffi.sizeof(self.colorData) == 9 * 4)

	self.colorBuffer = require 'gl.arraybuffer'{
		data = self.colorData,
		size = ffi.sizeof(self.colorData),
	}

	self.obj = require 'gl.sceneobject'{
		program = self.program,
		geometry = self.geometry,
		attrs = {
			vertex = {
				buffer = self.vertexBuffer,
			},
			color = {
				buffer = self.colorBuffer,
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
