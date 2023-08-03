#!/usr/bin/env luajit

local ffi = require 'ffi'
local template = require 'template'
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

	-- TODO gl.get() function for global gets
	-- each global size dim must be <= this
	local maxComputeWorkGroupCount = vec3i(GLProgram:get'GL_MAX_COMPUTE_WORK_GROUP_COUNT')
	print('GL_MAX_COMPUTE_WORK_GROUP_COUNT = '..maxComputeWorkGroupCount)

	-- each local size dim must be <= this
	local maxComputeWorkGroupSize = vec3i(GLProgram:get'GL_MAX_COMPUTE_WORK_GROUP_SIZE')
	print('GL_MAX_COMPUTE_WORK_GROUP_SIZE = '..maxComputeWorkGroupSize)

	-- the product of all local size dims must be <= this
	-- also, this is >= 1024
	local maxComputeWorkGroupInvocations = GLProgram:get'GL_MAX_COMPUTE_WORK_GROUP_INVOCATIONS'
	print('GL_MAX_COMPUTE_WORK_GROUP_INVOCATIONS = '..maxComputeWorkGroupInvocations)
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

	local localSize = vec3i(32,32,1)
	self.computeShader = GLProgram{
		computeCode = template([[
#version 460

layout(local_size_x=<?=localSize.x
	?>, local_size_y=<?=localSize.y
	?>, local_size_z=<?=localSize.z
	?>) in;

layout(rgba32f, binding=0) uniform writeonly image2D dstTex;
layout(rgba32f, binding=1) uniform readonly image2D srcTex;

void main() {
	ivec2 itc = ivec2(gl_GlobalInvocationID.xy);
	vec4 pixel = imageLoad(srcTex, itc);
	pixel.xy = pixel.yx;
	pixel.z = 1.;
	imageStore(dstTex, itc, pixel);
}
]], 	{
			localSize = localSize,
		})
	}
	glreport'here'

	self.computeShader:use()

	-- TODO how do I get the uniform's read/write access, or its format?
	-- or do I have to input that twice, both in the shader code as its glsl-format and in the glBindImageTexture call as a gl enum?

	self.computeShader:bindImage(0, dstTex, gl.GL_RGBA32F, gl.GL_WRITE_ONLY)
	self.computeShader:bindImage(1, srcTex, gl.GL_RGBA32F, gl.GL_READ_ONLY)

	gl.glDispatchCompute(
		math.ceil(w / tonumber(localSize.x)),
		math.ceil(h / tonumber(localSize.y)),
		1)

	gl.glMemoryBarrier(gl.GL_SHADER_IMAGE_ACCESS_BARRIER_BIT)
	--gl.glMemoryBarrier(gl.GL_ALL_BARRIER_BITS)

	--srcTex:unbindImage(1)
	--dstTex:unbindImage(0)
	self.computeShader:useNone()
	glreport'here'

--[[
	for _,uniform in ipairs(self.computeShader.uniforms) do
		print(require 'ext.tolua'(uniform))
	end
--]]
--[[
	{arraySize=1, loc=0, name="dstTex", setters={glsltype="image2D"}, type=gl.GL_IMAGE_2D}
	{arraySize=1, loc=1, name="srcTex", setters={glsltype="image2D"}, type=gl.GL_IMAGE_2D}
--]]

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
