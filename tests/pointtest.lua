#!/usr/bin/env luajit
local cmdline = require 'ext.cmdline'(...)
local op = require 'ext.op'
local ffi = require 'ffi'
local sdl = require 'ffi.req' 'sdl'
local vec3f = require 'vec-ffi.vec3f'
local gl = require 'gl.setup'(cmdline.gl or 'OpenGL')
local glreport = require 'gl.report'
local GLSceneObject = require 'gl.sceneobject'

local matrix_ffi = require 'matrix.ffi'
matrix_ffi.real = 'float'	-- default matrix_ffi type


local Test = require 'glapp.orbit'()
Test.viewUseBuiltinMatrixMath = true
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

	self.sceneObj = GLSceneObject{
		vertexes = {
			size = numPts * ffi.sizeof'vec3f_t',
			data = self.vertexCPUData,
			count = numPts,
			dim = 3,
		},
		program = {
			version = 'latest',
			header = 'precision highp float;',
			vertexCode = [[
in vec3 vertex;
in vec3 color;
out vec3 colorv;

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;

void main() {
	colorv = color;
	gl_Position = projectionMatrix * (modelViewMatrix * vec4(vertex, 1.));
	gl_PointSize = dot(color, vec3(50., 10., 1.));
}
]],
			fragmentCode = [[
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
		},
		geometry = {
			mode = gl.GL_POINTS,
		},
		attrs = {
			color = {
				buffer = {
					size = numPts * ffi.sizeof'vec3f_t',
					data = self.colorCPUData,
				},
			},
		},
	}
end

local hasPointSize = op.safeindex(gl, 'GL_PROGRAM_POINT_SIZE')
function Test:update()
	Test.super.update(self)

	gl.glClearColor(0, 0, 0, 0)
	gl.glClear(bit.bor(gl.GL_COLOR_BUFFER_BIT, gl.GL_DEPTH_BUFFER_BIT))

	local t = sdl.SDL_GetTicks() / 1000	-- gettime?
	self.view.mvMat:applyRotate(math.rad(t * 30), 0, 1, 0)
	self.view.mvProjMat:mul4x4(self.view.projMat, self.view.mvMat)

	gl.glEnable(gl.GL_DEPTH_TEST)
	if hasPointSize then
		gl.glEnable(gl.GL_PROGRAM_POINT_SIZE)
		gl.glEnable(gl.GL_POINT_SPRITE)
	end

	self.sceneObj.uniforms.modelViewMatrix = self.view.mvMat.ptr
	self.sceneObj.uniforms.projectionMatrix = self.view.projMat.ptr
	self.sceneObj:draw()

	if hasPointSize then
		gl.glDisable(gl.GL_POINT_SPRITE)
		gl.glDisable(gl.GL_PROGRAM_POINT_SIZE)
	end
	gl.glDisable(gl.GL_DEPTH_TEST)

	glreport'here'
end

return Test():run()
