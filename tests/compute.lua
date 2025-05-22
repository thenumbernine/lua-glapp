#!/usr/bin/env luajit
local cmdline = require 'ext.cmdline'(...)
local sdl, SDLApp = require 'sdl.setup'(cmdline.sdl or '2')
local gl = require 'gl.setup'(cmdline.gl or 'OpenGL')
local ffi = require 'ffi'

-- gles3 doesn't define compute so ...
-- TODO go by this?
--   https://community.arm.com/arm-community-blogs/b/graphics-gaming-and-vr-blog/posts/get-started-with-compute-shaders
for l in ([[
enum { GL_COMPUTE_SHADER = 37305 };
enum { GL_MAX_COMPUTE_UNIFORM_BLOCKS = 37307 };
enum { GL_MAX_COMPUTE_TEXTURE_IMAGE_UNITS = 37308 };
enum { GL_MAX_COMPUTE_IMAGE_UNIFORMS = 37309 };
enum { GL_MAX_COMPUTE_SHARED_MEMORY_SIZE = 33378 };
enum { GL_MAX_COMPUTE_UNIFORM_COMPONENTS = 33379 };
enum { GL_MAX_COMPUTE_ATOMIC_COUNTER_BUFFERS = 33380 };
enum { GL_MAX_COMPUTE_ATOMIC_COUNTERS = 33381 };
enum { GL_MAX_COMBINED_COMPUTE_UNIFORM_COMPONENTS = 33382 };
enum { GL_MAX_COMPUTE_WORK_GROUP_INVOCATIONS = 37099 };
enum { GL_MAX_COMPUTE_WORK_GROUP_COUNT = 37310 };
enum { GL_MAX_COMPUTE_WORK_GROUP_SIZE = 37311 };
enum { GL_COMPUTE_WORK_GROUP_SIZE = 33383 };
enum { GL_UNIFORM_BLOCK_REFERENCED_BY_COMPUTE_SHADER = 37100 };
enum { GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_COMPUTE_SHADER = 37101 };
enum { GL_COMPUTE_SHADER_BIT = 32 };
enum { GL_COMPUTE_TEXTURE = 33440 };
enum { GL_COMPUTE_SUBROUTINE = 37613 };
enum { GL_COMPUTE_SUBROUTINE_UNIFORM = 37619 };
enum { GL_REFERENCED_BY_COMPUTE_SHADER = 37643 };
enum { GL_MAX_COMPUTE_SHADER_STORAGE_BLOCKS = 37083 };
enum { GL_COMPUTE_SHADER_INVOCATIONS = 33525 };
typedef void ( * PFNGLDISPATCHCOMPUTEPROC) (GLuint num_groups_x, GLuint num_groups_y, GLuint num_groups_z);
typedef void ( * PFNGLDISPATCHCOMPUTEINDIRECTPROC) (GLintptr indirect);
enum { GL_IMAGE_2D = 36941 };
enum { GL_WRITE_ONLY = 35001 };
]]):gmatch'[^\n]+' do
	xpcall(function()
		ffi.cdef(l)
	end, function(err)
		print(err)
	end)
end

local template = require 'template'
local GLApp = require 'glapp'
local glreport = require 'gl.report'
local GLTex2D = require 'gl.tex2d'
local Image = require 'image'
local vec3i = require 'vec-ffi.vec3i'

local App = GLApp:subclass()

function App:initGL(...)
	if App.super.initGL then
		App.super.initGL(self, ...)
	end

	local GLGlobal = require 'gl.global'

	-- each global size dim must be <= this
	print(GLGlobal:get'GL_MAX_COMPUTE_WORK_GROUP_COUNT')
	local maxComputeWorkGroupCount = vec3i(GLGlobal:get'GL_MAX_COMPUTE_WORK_GROUP_COUNT')
	print('GL_MAX_COMPUTE_WORK_GROUP_COUNT = '..maxComputeWorkGroupCount)

	-- each local size dim must be <= this
	local maxComputeWorkGroupSize = vec3i(GLGlobal:get'GL_MAX_COMPUTE_WORK_GROUP_SIZE')
	print('GL_MAX_COMPUTE_WORK_GROUP_SIZE = '..maxComputeWorkGroupSize)

	-- the product of all local size dims must be <= this
	-- also, this is >= 1024
	local maxComputeWorkGroupInvocations = GLGlobal:get'GL_MAX_COMPUTE_WORK_GROUP_INVOCATIONS'
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
	self.computeShader = require 'gl.program'{
		version = 'latest',
		precision = 'best',
		computeCode = template([[
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
		-- TODO how do I get the uniform's read/write access, or its format?
		-- or do I have to input that twice, both in the shader code as its glsl-format and in the glBindImageTexture call as a gl enum?
		:bindImage(0, dstTex, gl.GL_RGBA32F, gl.GL_WRITE_ONLY)
		:bindImage(1, srcTex, gl.GL_RGBA32F, gl.GL_READ_ONLY)

	glreport'here'

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
	img:save'src-resaved.png'

	-- this is reading dstTex correctly
	img = img * 0
	dstTex:toCPU(img.buffer, 0)
	dstTex:unbind()
	glreport'here'
	img:save'dst.png'

	print'done'
	self:requestExit()
end

return App():run()
