#!/usr/bin/env luajit
local ffi = require 'ffi'
local sdl = require 'ffi.req' 'sdl'
local vec3f = require 'vec-ffi.vec3f'
local gl = require 'gl'
local glreport = require 'gl.report'
local GLProgram = require 'gl.program'
local GLArrayBuffer = require 'gl.arraybuffer'
local GLGeometry = require 'gl.geometry'
local GLSceneObject = require 'gl.sceneobject'

local matrix_ffi = require 'matrix.ffi'
matrix_ffi.real = 'float'	-- default matrix_ffi type


local Test = require 'glapp.orbit'()

Test.title = "Spinning Points"

local numPts

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


	local ires = 10
	local jres = 10
	numPts = ires * jres
	self.vertexCPUData = ffi.new('vec3f_t[?]', numPts)
	self.colorCPUData = ffi.new('vec3f_t[?]', numPts)

	local umin, umax = -1, 1
	local vmin, vmax = -1, 1
	local f = function(u,v) return u*u + v*v end
	for j=0,jres-1 do
		local t = (j+.5)/jres
		local v = t * (vmax - vmin) + vmin
		for i=0,ires-1 do
			local s = (i+.5)/ires
			local u = s * (umax - umin) + umin
			self.vertexCPUData[i + ires * j]:set(u, v, f(u,v))
			self.colorCPUData[i + ires * j]:set(s, t, .5)
		end
	end

	self.vertexGPUData = GLArrayBuffer{
		size = numPts * ffi.sizeof'vec3f_t',
		data = self.vertexCPUData,
	}:unbind()

	self.colorGPUData = GLArrayBuffer{
		size = numPts * ffi.sizeof'vec3f_t',
		data = self.colorCPUData,
	}:unbind()

	self.shader = GLProgram{
		vertexCode = [[
#version 460

in vec3 pos;
in vec3 color;
out vec3 colorv;

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;

void main() {
	colorv = color;
	gl_Position = projectionMatrix * (modelViewMatrix * vec4(pos, 1.));
	gl_PointSize = dot(color, vec3(50., 10., 1.));
}
]],
		fragmentCode = [[
#version 460

in vec3 colorv;
out vec4 colorf;

void main() {
	vec2 d = gl_PointCoord.xy * 2. - 1.;
	float rsq = dot(d, d);
	if (rsq > 1.) discard;
	colorf = vec4(colorv, 1.);
	colorf.rg += .5 * d;
}
]],
	}:useNone()

	self.geometry = GLGeometry{
		mode = gl.GL_POINTS,
		count = numPts,
	}

	self.sceneObj = GLSceneObject{
		program = self.shader,
		geometry = self.geometry,
		attrs = {
			pos = self.vertexGPUData,
			color = self.colorGPUData,
		},
	}
end


local modelViewMatrix = matrix_ffi.zeros{4,4}
local projectionMatrix = matrix_ffi.zeros{4,4}

function Test:update()
	Test.super.update(self)

	gl.glClearColor(0, 0, 0, 0)
	gl.glClear(bit.bor(gl.GL_COLOR_BUFFER_BIT, gl.GL_DEPTH_BUFFER_BIT))

	local t = sdl.SDL_GetTicks() / 1000	-- gettime?
	gl.glRotatef(.3 * t * 100, 0, 1, 0)

	gl.glGetFloatv(gl.GL_MODELVIEW_MATRIX, modelViewMatrix.ptr)
	gl.glGetFloatv(gl.GL_PROJECTION_MATRIX, projectionMatrix.ptr)

	gl.glEnable(gl.GL_DEPTH_TEST)
	gl.glEnable(gl.GL_PROGRAM_POINT_SIZE)
	gl.glEnable(gl.GL_POINT_SPRITE)

	self.sceneObj.uniforms.modelViewMatrix = modelViewMatrix.ptr
	self.sceneObj.uniforms.projectionMatrix = projectionMatrix.ptr
	self.sceneObj:draw()

	gl.glDisable(gl.GL_POINT_SPRITE)
	gl.glDisable(gl.GL_PROGRAM_POINT_SIZE)
	gl.glDisable(gl.GL_DEPTH_TEST)
	
	glreport'here'
end

return Test():run()
