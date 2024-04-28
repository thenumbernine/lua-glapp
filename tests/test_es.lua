#!/usr/bin/env luajit
local ffi = require 'ffi'
local gl = require 'gl.setup' (... or 'OpenGLES3')
local getTime = require 'ext.timer'.getTime

require 'glapp.view'.useBuiltinMatrixMath = true		-- don't use glMatrix* calls

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
	
Test.viewDist = 20

function Test:initGL()
	local version = ffi.new'SDL_version[1]'
	local sdl = require 'ffi.req' 'sdl'
	sdl.SDL_GetVersion(version)
	print'SDL_GetVersion:'
	print(version[0].major..'.'..version[0].minor..'.'..version[0].patch)
	
	-- Supported versions are: 1.10, 1.20, 1.30, 1.40, 1.50, 3.30, 4.00, 4.10, 4.20, 4.30, 4.40, 4.50, 4.60, 1.00 ES, 3.00 ES, 3.10 ES, and 3.20 ES
	-- es versions:
	--local glslversion = '320 es'	-- works
	--local glslversion = '310 es'	-- works
	local glslversion = '300 es'	-- works
	--local glslversion = '100'	-- fails
	-- non-es versions:
	--local glslversion = '460'	-- works
	--local glslversion = '450'	-- works
	--local glslversion = '440'	-- works
	--local glslversion = '430'	-- works
	--local glslversion = '420'	-- works
	--local glslversion = '410'	-- works
	--local glslversion = '400'	-- works
	--local glslversion = '330'	-- works
	--local glslversion = '150'	-- fails
	--local glslversion = '140'	-- fails
	--local glslversion = '130'	-- fails
	--local glslversion = '120'	-- fails
	--local glslversion = '110'	-- fails


	-- default shader
	local glslheader = '#version '..glslversion..'\n'
		..'precision highp float;\n'
	self.shader = require 'gl.program'{
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
