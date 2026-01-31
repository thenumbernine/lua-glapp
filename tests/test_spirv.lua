#!/usr/bin/env luajit
--[[
test of GL_ARB_gl_spirv
--]]
require 'ext'
local ffi = require 'ffi'

--[[ does something in this cause segfaults?
require 'gl.env'()
--]]
-- [[
local gl = require 'gl.setup'(cmdline.gl)
local GLSceneObject = require 'gl.sceneobject'
local GLUniformBuffer = require 'gl.uniformbuffer'
--]]

local useSPIRV = true

local App = require 'imgui.appwithorbit'()

App.title = 'SPIRV Shader Test'
App.viewDist = 3

function App:initGL()
	App.super.initGL(self)
	self.view.ortho = true
	self.view.orthoSize = 1

	local glGlobal = require 'gl.global'
	local binaryFormats = table{glGlobal:get'GL_SHADER_BINARY_FORMATS'}
	print('GL_SHADER_BINARY_FORMATS', tolua(binaryFormats))

	local GL_SHADER_BINARY_FORMAT_SPIR_V = op.safeindex(gl, 'GL_SHADER_BINARY_FORMAT_SPIR_V') or 38225
	local binaryFormat = GL_SHADER_BINARY_FORMAT_SPIR_V
	assert(binaryFormats:find(GL_SHADER_BINARY_FORMAT_SPIR_V), "failed to find GL_SHADER_BINARY_FORMAT_SPIR_V supported binary format")

	local vertexCode = [[
#version 450
precision highp float;
layout(location=0) in vec2 vertex;
layout(location=0) out vec2 posv;

#if 0	// as uniform. location required for spirv

layout(location=0) uniform mat4 mvProjMat;

#else	// as a uniform-block, which is required for Vulkan (right?)

layout(std140, binding=0) uniform VertexUniforms {
	mat4 mvProjMat;
};

#endif

void main() {
	posv = vertex;
	gl_Position = mvProjMat * vec4(vertex, 0., 1.);
}
]]

	local fragmentCode = [[
#version 450
precision highp float;
layout(location=0) in vec2 posv;
layout(location=0) out vec4 fragColor;
#define dvec2 vec2
#define double float
void main() {
	dvec2 c = posv;
	dvec2 z = vec2(0., 0.);
	double iter = 0.;
	double znorm = 0.;
	for (; iter < 100.; ++iter) {
		z = dvec2( z.x*z.x - z.y*z.y + c.x, 2.*z.x*z.y + c.y );
		znorm = dot(z,z);
		if (znorm > 4.) {
			iter = iter - .5 * double(log(float(znorm)));
			break;
		}
	}

	vec2 zf = vec2(z);
	float zangle = atan(zf.y, zf.x);
	fragColor = vec4(zangle, znorm, iter, 1.);
}
]]
	if useSPIRV then
		path'shader.vert':write(vertexCode)
		path'shader.frag':write(fragmentCode)
		assert(os.exec'glslangValidator -S vert --glsl-version 450 --target-env opengl shader.vert -o shader-vert.spv')
		assert(os.exec'glslangValidator -S frag --glsl-version 450 --target-env opengl shader.frag -o shader-frag.spv')
		assert(os.exec'spirv-link shader-vert.spv shader-frag.spv -o shader.spv')
	end
	self.sceneObj = GLSceneObject{
		program = not useSPIRV and {
			vertexCode = vertexCode,
			fragmentCode = fragmentCode,

			--[[
			For using uniform-blocks instead of uniforms.
			Fun Fact:
			With glShaderSource with GLES3, you cannot specify binding= in the GLSL
			But with glShaderBinary + SPIRV you *can only* specify the block binding in the GLSL
				(since the compile phase seems to lose all names, so you have no other way to identify blocks beyond checking sizes or random guesses)
			--]]
			uniformBlocks = {
				VertexUniforms = {
					binding = 0,
				},
			},
		} or {
			binaryFormat = binaryFormat,
			--[[ loading one binary shader-module at a time per glShaderBinary() call
-- NOT WORKING AND NO ERROR
			vertexBinary = assert(path'shader-vert.spv':read()),
			fragmentBinary = assert(path'shader-frag.spv':read()),
			--]]
			-- [[ loading all binaries in one single glShaderBinary() call
-- NOT WORKING AND NO ERROR
			multipleBinary = assert(path'shader.spv':read()),
			-- can you infer this from the file?
			multipleBinaryStages = {'vertex', 'fragment'},
			--]]
		},
		vertexes = {
			dim = 2,
			data = {
				-2, -2,
				2, -2,
				-2, 2,
				2, 2,
			},
		},
		geometry = {
			mode = gl.GL_TRIANGLE_STRIP,
			count = 4,
		},
	}

	local uniformBlocks = self.sceneObj.program.uniformBlocks
	print('uniform blocks:')
	print(tolua(table.mapi(uniformBlocks, function(x) return x end)))

	local vertexUniformBlock =
		-- This will exist for the GLSL-source-compiled shader.
		-- But it won't work with binary shader ... cuz no names in SPIR-V ?
		uniformBlocks.VertexUniforms
		-- would I need a .uniformBlockForBinding[] ?
		or uniformBlocks[1]
assert.eq(vertexUniformBlock.dataSize, ffi.sizeof'float' * 16)
	self.vertexUniformBuf = GLUniformBuffer{
		data = self.view.mvProjMat.ptr,
		size = ffi.sizeof'float' * 16,
		usage = gl.GL_DYNAMIC_DRAW,
		binding = vertexUniformBlock.binding,
	}:unbind()
end

function App:update()
	App.super.update(self)

	gl.glClear(bit.bor(gl.GL_COLOR_BUFFER_BIT, gl.GL_DEPTH_BUFFER_BIT))

--[[ using uniforms
	self.sceneObj.uniforms.mvProjMat = self.view.mvProjMat.ptr
--]]
-- [[ using uniform-blocks:
	self.vertexUniformBuf
		:bind()
		:updateData()
		:unbind()
--]]
	self.sceneObj:draw()

require'gl.report''here'
end

return App():run()
