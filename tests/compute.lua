#!/usr/bin/env luajit

local ffi = require 'ffi'
local class = require 'ext.class'
local GLApp = require 'glapp'
local gl = require 'gl'
local glreport = require 'gl.report'
local GLProgram = require 'gl.program'
local GLTex2D = require 'gl.tex2d'
local Image = require 'image'
local vec3i = require 'vec-ffi.vec3i'

local App = class(GLApp)

function App:initGL(...)
	if App.super.initGL then
		App.super.initGL(self, ...)
	end

	local function geti3(pname)
		local v = vec3i()
		gl.glGetIntegeri_v(pname, 0, v.s+0)
		gl.glGetIntegeri_v(pname, 1, v.s+1)
		gl.glGetIntegeri_v(pname, 2, v.s+2)
		return v
	end

	-- each global size dim must be <= this
	local maxComputeWorkGroupCount = geti3(gl.GL_MAX_COMPUTE_WORK_GROUP_COUNT)
	print('GL_MAX_COMPUTE_WORK_GROUP_COUNT = '..maxComputeWorkGroupCount)

	-- each local size dim must be <= this
	local maxComputeWorkGroupSize = geti3(gl.GL_MAX_COMPUTE_WORK_GROUP_SIZE)
	print('GL_MAX_COMPUTE_WORK_GROUP_SIZE = '..maxComputeWorkGroupSize)

	-- the product of all local size dims must be <= this
	-- also, this is >= 1024
	local maxComputeWorkGroupInvocations = ffi.new('int[1]', 0)
	gl.glGetIntegerv(gl.GL_MAX_COMPUTE_WORK_GROUP_INVOCATIONS, maxComputeWorkGroupInvocations)
	print('GL_MAX_COMPUTE_WORK_GROUP_INVOCATIONS = '..maxComputeWorkGroupInvocations[0])
	glreport'here'

	local w, h = 256, 256
	local img = Image(w, h, 4, 'float', function(i,j)
		return i/w, j/h, .5, 1
	end)
	local srcTex = GLTex2D{
		internalFormat = gl.GL_RGBA32F,
		width = w,
		height = h,
		format = gl.GL_RGBA,
		type = gl.GL_FLOAT,
		data = img.buffer,
		minFilter = gl.GL_LINEAR,
		magFilter = gl.GL_LINEAR,
		generateMipmap = true,
	}
	glreport'here'
	
	local img = Image(w, h, 4, 'float', function(i,j) return 0,0,0,1 end)
	local dstTex = GLTex2D{
		internalFormat = gl.GL_RGBA32F,
		width = w,
		height = h,
		format = gl.GL_RGBA,
		type = gl.GL_FLOAT,	
		data = img.buffer,	-- can data be null?
		minFilter = gl.GL_LINEAR,
		magFilter = gl.GL_LINEAR,
		generateMipmap = true,
	}
	glreport'here'

	self.computeShader = GLProgram{
		computeCode = [[
#version 460

layout(local_size_x=32, local_size_y=32, local_size_z=1) in;

layout(rgba32f, binding=0) uniform writeonly image2D dstTex;
layout(rgba32f, binding=1) uniform readonly image2D srcTex;

void main() {
	ivec2 itc = ivec2(gl_GlobalInvocationID.xy);
	vec4 pixel = imageLoad(srcTex, itc);
	pixel.xy = pixel.yx;
	pixel.z = 1.;
	imageStore(dstTex, itc, pixel);
}
]]
	}
	glreport'here'

	self.computeShader:use()
	
	--dstTex:bindImage(0)
	gl.glBindImageTexture(
		0,					-- unit
		dstTex.id,			-- texture
		0,					-- level
		gl.GL_FALSE,		-- layered
		0,					-- layer
		gl.GL_WRITE_ONLY,	-- access.  can be derived from shader program (right?).
		gl.GL_RGBA32F		-- format.  can be derived from shader program.
	)
	-- ... hmm, format deserves a connectio with the detected uniform-type-from-program
	-- so maybe glBindImageTexture should be a function of the program and not of the texture?
	-- or maybe both: self.computeShader:bindImageTexture(0, dstTex)

	--srcTex:bindImage(1)
	gl.glBindImageTexture(
		1,					-- unit
		srcTex.id,			-- texture
		0,					-- level
		gl.GL_FALSE,		-- layered
		0,					-- layer
		gl.GL_READ_ONLY,	-- access
		gl.GL_RGBA32F		-- format
	)

	gl.glDispatchCompute(w,h,1)
	--gl.glDispatchCompute(1,1,1)
	--gl.glDispatchCompute(8,8,1)
	
	--gl.glMemoryBarrier(gl.GL_SHADER_IMAGE_ACCESS_BARRIER_BIT)
	gl.glMemoryBarrier(gl.GL_ALL_BARRIER_BITS)
	
	--srcTex:unbindImage(1)
	--dstTex:unbindImage(0)
	self.computeShader:useNone()
	glreport'here'

	srcTex:toCPU(img.buffer, 0)
	srcTex:unbind()
	glreport'here'
	img:save'src.png'

	-- this is reading dstTex correctly
	img = img * 0
	dstTex:toCPU(img.buffer, 0)
	dstTex:unbind()
	glreport'here'
	img:save'dst.png'

	self:requestExit()
end

return App():run()
