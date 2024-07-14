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

	local GLProgram = require 'gl.program'
	local vertexShader = GLProgram.VertexShader{
		code = [[
#version 300 es
precision highp float;
in vec2 vertex;
in vec3 color;
out vec4 colorv;
uniform mat4 mvProjMat;
void main() {
	colorv = vec4(color, 1.);
	gl_Position = mvProjMat * vec4(vertex, 0., 1.);
}
]],
	}

	local fragmentShader = GLProgram.FragmentShader{
		code = [[
#version 300 es
precision highp float;
in vec4 colorv;
out vec4 fragColor;
void main() {
	fragColor = colorv;
}
]],
	}

	local program = GLProgram{
		shaders = {
			vertexShader,
			fragmentShader,
		},
	}
	gl.glUseProgram(0)

	self.program = program
	do
		local result = ffi.new'GLint[1]'
		gl.glGetProgramiv(program.id, gl.GL_INFO_LOG_LENGTH, result)
		local length = result[0]
		print('length', length)		
		local log = ffi.new('char[?]',length+1)
		local result = ffi.new'GLsizei[1]'
		gl.glGetProgramInfoLog(program.id, length, result, log);
		print('double check length', result[0])		
		print('log:')
		print(ffi.string(log))
	end

	self.vertexData = ffi.new('float[6]',
		-5, -4,
		5, -4,
		0, 6
	)
	assert(ffi.sizeof(self.vertexData) == 6 * 4)
	do
		local id = ffi.new'GLuint[1]'
		gl.glGenBuffers(1, id)
		self.vertexBufferID = id[0]
		gl.glBindBuffer(gl.GL_ARRAY_BUFFER, self.vertexBufferID)
		gl.glBufferData(gl.GL_ARRAY_BUFFER, 6 * 4, self.vertexData, gl.GL_STATIC_DRAW)
		gl.glBindBuffer(gl.GL_ARRAY_BUFFER, 0)
	end

	self.colorData = ffi.new('float[9]', 
		1, 0, 0,
		0, 1, 0,
		0, 0, 1
	)
	assert(ffi.sizeof(self.colorData) == 9 * 4)
	do
		local id = ffi.new'GLuint[1]'
		gl.glGenBuffers(1, id)
		self.colorBufferID = id[0]
		gl.glBindBuffer(gl.GL_ARRAY_BUFFER, self.colorBufferID)
		gl.glBufferData(gl.GL_ARRAY_BUFFER, 9 * 4, self.colorData, gl.GL_STATIC_DRAW)
		gl.glBindBuffer(gl.GL_ARRAY_BUFFER, 0)
	end

	self.vertexAttrLoc = gl.glGetAttribLocation(program.id, 'vertex')
	self.colorAttrLoc = gl.glGetAttribLocation(program.id, 'color')
	
	--[[ vao or not
	do
		local id = ffi.new'GLuint[1]'
		gl.glGenVertexArrays(1, id)
		self.vaoID = id[0]
		gl.glBindVertexArray(self.vaoID)
		
		gl.glEnableVertexAttribArray(self.vertexAttrLoc)
		gl.glBindBuffer(gl.GL_ARRAY_BUFFER, self.vertexBufferID)
		gl.glVertexAttribPointer(self.vertexAttrLoc, 2, gl.GL_FLOAT, gl.GL_FALSE, 0, ffi.null)
		gl.glBindBuffer(gl.GL_ARRAY_BUFFER, 0)

		gl.glEnableVertexAttribArray(self.colorAttrLoc)
		gl.glBindBuffer(gl.GL_ARRAY_BUFFER, self.colorBufferID)
		gl.glVertexAttribPointer(self.colorAttrLoc, 3, gl.GL_FLOAT, gl.GL_FALSE, 0, ffi.null)
		gl.glBindBuffer(gl.GL_ARRAY_BUFFER, 0)
	
		gl.glBindVertexArray(0)
	end
	--]]

	self.mvProjMatUniformLoc = program.uniforms.mvProjMat.loc
	gl.glClearColor(0, 0, 0, 1)
end

function Test:update()
	Test.super.update(self)
	gl.glClear(gl.GL_COLOR_BUFFER_BIT)

	local t = getTime()
	self.view.mvMat:applyRotate(math.rad(t * 30), 0, 1, 0)
	self.view.mvProjMat:mul4x4(self.view.projMat, self.view.mvMat)

	local program = self.program

	gl.glUseProgram(program.id)
	
	gl.glUniformMatrix4fv(self.mvProjMatUniformLoc, 1, gl.GL_FALSE, self.view.mvProjMat.ptr)
	
	if self.vaoID then
		gl.glBindVertexArray(self.vaoID)
	else
		gl.glEnableVertexAttribArray(self.vertexAttrLoc)
		gl.glBindBuffer(gl.GL_ARRAY_BUFFER, self.vertexBufferID)
		gl.glVertexAttribPointer(self.vertexAttrLoc, 2, gl.GL_FLOAT, gl.GL_FALSE, 0, ffi.null)
		gl.glBindBuffer(gl.GL_ARRAY_BUFFER, 0)
		
		gl.glEnableVertexAttribArray(self.colorAttrLoc)
		gl.glBindBuffer(gl.GL_ARRAY_BUFFER, self.colorBufferID)
		gl.glVertexAttribPointer(self.colorAttrLoc, 3, gl.GL_FLOAT, gl.GL_FALSE, 0, ffi.null)
		gl.glBindBuffer(gl.GL_ARRAY_BUFFER, 0)
	end
	
	gl.glDrawArrays(gl.GL_TRIANGLES, 0, 6)

	if self.vaoID then
		gl.glBindVertexArray(0)
	else
		gl.glDisableVertexAttribArray(self.vertexAttrLoc)
		gl.glDisableVertexAttribArray(self.colorAttrLoc)
	end

	gl.glUseProgram(0)
end

return Test():run()
