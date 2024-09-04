#!/usr/bin/env luajit
-- https://registry.khronos.org/OpenGL-Refpages/gl4/html/glGet.xhtml
require 'ext'
local ffi = require 'ffi'

-- specify GL version first:
--local gl = require 'gl.setup'()	-- for desktop GL
--local gl = require 'gl.setup' 'OpenGLES1'	-- for GLES1 ... but GLES1 has no shaders afaik?
--local gl = require 'gl.setup' 'OpenGLES2'	-- for GLES2
--local gl = require 'gl.setup' 'OpenGLES3'	-- for GLES3

local gl = require 'gl.setup'((...))	-- choose at cmdline

local App = require 'glapp':subclass()
function App:initGL()
	local glGlobal = require 'gl.global'

	local ffireq = require 'ffi.req'
	local egl = op.land(pcall(ffireq, 'EGL'))
	if not egl then
		print('EGL not found')
	else
		-- how do I find GLES version?  cuz GL doen't show it ...
		-- GLES/OpenGLES1.h has GL_VERSION, but GL_VERSION returns the same as it does for non-ES ...
		-- [[ can EGL version help?
		-- https://registry.khronos.org/EGL/sdk/docs/man/html/eglIntro.xhtml
		-- seems no
		local display = egl.eglGetDisplay(egl.EGL_DEFAULT_DISPLAY)
		print('display', eglDisplay)
		egl.eglInitialize(display, nil, nil)
		local attributeListSrc = {
			egl.EGL_RED_SIZE, 1,
			egl.EGL_GREEN_SIZE, 1,
			egl.EGL_BLUE_SIZE, 1,
			egl.EGL_NONE
		}
		local attributeList = ffi.new('EGLint[?]', #attributeListSrc)
		for i=1,#attributeListSrc do
			attributeList[i-1] = attributeListSrc[i]
		end
		local pconfig = ffi.new('EGLConfig[1]')
		local pnumConfig = ffi.new('EGLint[1]')
		egl.eglChooseConfig(display, attributeList, pconfig, 1, pnumConfig);
		local context = egl.eglCreateContext(display, config, egl.EGL_NO_CONTEXT, nil)
		print()
		--]]

		for _,field in ipairs{
			'EGL_CLIENT_APIS',
			'EGL_VENDOR',
			'EGL_VERSION',
			'EGL_EXTENSIONS',
		} do
			local strptr = egl.eglQueryString(egl.EGL_NO_DISPLAY, egl[field])
			local str = strptr ~= nil and ffi.string(strptr) or 'null'
			print(field, str)
		end
	end

	local function get(name, ...)
		return glGlobal:get(name, ...)
	end
	local function show(name, ...)
		local result = table.pack(get(name, ...))
		io.write(name)
		local n = select('#', ...)
		if n > 0 then
			io.write'['
			for i=1,n do
				if i > 1 then io.write',' end
				io.write((select(i, ...)))
			end
			io.write']'
		end
		print(' = '..result:mapi(tostring):concat' ')
		return result:unpack()
	end

--[[ can it be this easy? ... not yet .. and also TODO store them as indexes also for in-order iteration
	for _,name in ipairs(table.keys(glGlobal.getInfo):sort()) do
		show(name)
	end
do self:requestExit() return end
--]]
	show'GL_VENDOR'
	show'GL_RENDERER'
	show'GL_VERSION'
	show'GL_SHADING_LANGUAGE_VERSION'	-- TOOD only for version >= 4

	local version
	local majorVersion = get'GL_MAJOR_VERSION'
	local minorVersion = get'GL_MINOR_VERSION'
	if majorVersion ~= 'string'
	and minorVersion ~= 'string'
	then
		version = majorVersion + .1 * minorVersion
	else
		pcall(function()
			version = tonumber(glGlobal:get'GL_VERSION':split'%s+'[1])
		end)
	end
	print('GL_VERSION = '..tostring(version))

-- https://registry.khronos.org/OpenGL-Refpages/gl4/html/glGet.xhtml
-- https://registry.khronos.org/OpenGL-Refpages/es3.0/html/glGet.xhtml

	show'GL_MAJOR_VERSION'
	show'GL_MINOR_VERSION'
	show'GL_RED_BITS'				-- gles 300 but not gl 4
	show'GL_GREEN_BITS'						-- gles 300 but not gl 4
	show'GL_BLUE_BITS'						-- gles 300 but not gl 4 ?
	show'GL_ALPHA_BITS'						-- gles 300 but not gl 4 ?
	show'GL_DEPTH_BITS'						-- gles 300 but not gl 4 ?
	show'GL_STENCIL_BITS'				-- gles 300 but not gl 4
	show'GL_SUBPIXEL_BITS'

	show'GL_POINT_FADE_THRESHOLD_SIZE'			-- gl 4 but not gles 300
	show'GL_POINT_SIZE'			-- gl 4 but not gles 300
	show'GL_POINT_SIZE_GRANULARITY'			-- gl 4 but not gles 300
	show'GL_POINT_SIZE_RANGE'			-- gl 4 but not gles 300
	show'GL_ALIASED_POINT_SIZE_RANGE'		-- gles 300 but not gl 4 ?

	show'GL_LINE_SMOOTH'						-- gl 4 but not gles 300
	show'GL_LINE_SMOOTH_HINT'				-- gl 4 but not gles 300
	show'GL_LINE_WIDTH'
	show'GL_SMOOTH_LINE_WIDTH_RANGE'			-- gl 4 but not gles 300
	show'GL_SMOOTH_LINE_WIDTH_GRANULARITY'			-- gl 4 but not gles 300
	show'GL_ALIASED_LINE_WIDTH_RANGE'

	show'GL_POLYGON_SMOOTH'		-- gl 4 but not gles 300
	show'GL_POLYGON_SMOOTH_HINT'		-- gl 4 but not gles 300
	show'GL_POLYGON_OFFSET_FACTOR'
	show'GL_POLYGON_OFFSET_UNITS'
	show'GL_POLYGON_OFFSET_FILL'
	show'GL_POLYGON_OFFSET_LINE'			-- gl 4 but not gles 300
	show'GL_POLYGON_OFFSET_POINT'			-- gl 4 but not gles 300

	show'GL_BLEND'
	show'GL_BLEND_COLOR'
	show'GL_BLEND_DST_ALPHA'
	show'GL_BLEND_DST_RGB'
	show'GL_BLEND_EQUATION_RGB'
	show'GL_BLEND_EQUATION_ALPHA'			-- gles 300 but not gl 4 ?
	show'GL_BLEND_SRC_ALPHA'
	show'GL_BLEND_SRC_RGB'

	show'GL_COLOR_CLEAR_VALUE'
	show'GL_COLOR_LOGIC_OP'					-- gl 4 but not gles 300
	show'GL_COLOR_WRITEMASK'

	show'GL_LOGIC_OP_MODE'					-- gl 4 but not gles 300

	show'GL_NUM_COMPRESSED_TEXTURE_FORMATS'
	show'GL_COMPRESSED_TEXTURE_FORMATS'

-- and at this point I'm giving up on flagging all getters that cause segfaults  ... 3 out of the first 16 is too much
	show'GL_CONTEXT_FLAGS'					-- gl 4 but not gles 300
	show'GL_CULL_FACE'
	show'GL_CULL_FACE_MODE'
	show'GL_CURRENT_PROGRAM'
	show'GL_DEPTH_CLEAR_VALUE'
	show'GL_DEPTH_FUNC'
	show'GL_DEPTH_RANGE'
	show'GL_DEPTH_TEST'
	show'GL_DEPTH_WRITEMASK'
	show'GL_DITHER'
	show'GL_DOUBLEBUFFER'					-- gl 4 but not gles 300
	show'GL_DRAW_BUFFER'	-- works
	local maxDrawBuffers = show'GL_MAX_DRAW_BUFFERS'
	for i=0,maxDrawBuffers-1 do
		show('GL_DRAW_BUFFER', i)	 -- gl-error's ... but the docs dont really say the first version at which index-based getters for this were valid ...
	end

	show'GL_ACTIVE_TEXTURE'
	show'GL_ARRAY_BUFFER_BINDING'
	show'GL_DRAW_FRAMEBUFFER_BINDING'
	show'GL_READ_FRAMEBUFFER_BINDING'
	show'GL_ELEMENT_ARRAY_BUFFER_BINDING'
	show'GL_PIXEL_PACK_BUFFER_BINDING'
	show'GL_PIXEL_UNPACK_BUFFER_BINDING'
	show'GL_PROGRAM_PIPELINE_BINDING'			-- gl 4 but not gles 300
	show'GL_RENDERBUFFER_BINDING'
	show'GL_SAMPLER_BINDING'

	show'GL_FRAGMENT_SHADER_DERIVATIVE_HINT'
	show'GL_FRONT_FACE'						-- gles 300 but not gl 4
	show'GL_GENERATE_MIPMAP_HINT'			-- gles 300 but not gl 4
	show'GL_IMPLEMENTATION_COLOR_READ_FORMAT'
	show'GL_IMPLEMENTATION_COLOR_READ_TYPE'

	show'GL_MAX_COMBINED_SHADER_STORAGE_BLOCKS'	-- gl 4 but not gles 300.  segfault upon exit
	show'GL_MAX_DUAL_SOURCE_DRAW_BUFFERS'	-- gl 4 but not gles 300
	show'GL_MAX_3D_TEXTURE_SIZE'
	show'GL_MAX_ARRAY_TEXTURE_LAYERS'
	show'GL_MAX_COLOR_ATTACHMENTS'			-- gles 300 but not gl 4
	show'GL_MAX_CLIP_DISTANCES'				-- gl 4 but not gles 300
	show'GL_MAX_COLOR_TEXTURE_SAMPLES'				-- gl 4 but not gles 300
	show'GL_MAX_COMBINED_ATOMIC_COUNTERS'				-- gl 4 but not gles 300
	show'GL_MAX_COMBINED_FRAGMENT_UNIFORM_COMPONENTS'
	show'GL_MAX_COMBINED_GEOMETRY_UNIFORM_COMPONENTS'				-- gl 4 but not gles 300
	show'GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS'
	show'GL_MAX_COMBINED_UNIFORM_BLOCKS'
	show'GL_MAX_COMBINED_VERTEX_UNIFORM_COMPONENTS'
	show'GL_MAX_CUBE_MAP_TEXTURE_SIZE'
	show'GL_MAX_DEPTH_TEXTURE_SAMPLES'				-- gl 4 but not gles 300
	show'GL_MAX_ELEMENTS_INDICES'
	show'GL_MAX_ELEMENTS_VERTICES'
	show'GL_MAX_FRAGMENT_INPUT_COMPONENTS'
	show'GL_MAX_FRAGMENT_UNIFORM_COMPONENTS'
	show'GL_MAX_FRAGMENT_UNIFORM_VECTORS'
	show'GL_MAX_FRAGMENT_UNIFORM_BLOCKS'
	show'GL_MAX_GEOMETRY_INPUT_COMPONENTS'				-- gl 4 but not gles 300
	show'GL_MAX_GEOMETRY_OUTPUT_COMPONENTS'				-- gl 4 but not gles 300
	show'GL_MAX_GEOMETRY_TEXTURE_IMAGE_UNITS'				-- gl 4 but not gles 300
	show'GL_MAX_GEOMETRY_UNIFORM_BLOCKS'				-- gl 4 but not gles 300
	show'GL_MAX_GEOMETRY_UNIFORM_COMPONENTS'				-- gl 4 but not gles 300
	show'GL_MAX_INTEGER_SAMPLES'				-- gl 4 but not gles 300
	show'GL_MAX_PROGRAM_TEXEL_OFFSET'
	show'GL_MIN_PROGRAM_TEXEL_OFFSET'
	show'GL_MAX_RECTANGLE_TEXTURE_SIZE'			-- gl 4 but not gles 300
	show'GL_MAX_RENDERBUFFER_SIZE'
	show'GL_MAX_SAMPLES'						-- gles 300 but not gl 4
	show'GL_MAX_SAMPLE_MASK_WORDS'			-- gl 4 but not gles 300
	show'GL_MAX_SERVER_WAIT_TIMEOUT'
	show'GL_MAX_TEXTURE_BUFFER_SIZE'						-- gl 4 but not gles 300
	show'GL_MAX_TEXTURE_IMAGE_UNITS'
	show'GL_MAX_TEXTURE_LOD_BIAS'
	show'GL_MAX_TEXTURE_SIZE'
	show'GL_MAX_TRANSFORM_FEEDBACK_INTERLEAVED_COMPONENTS'	-- gles 300 but not gl 4
	show'GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_ATTRIBS'	-- gles 300 but not gl 4
	show'GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_COMPONENTS'	-- gles 300 but not gl 4
	show'GL_MAX_UNIFORM_BUFFER_BINDINGS'
	show'GL_MAX_UNIFORM_BLOCK_SIZE'
	show'GL_MAX_VARYING_COMPONENTS'
	show'GL_MAX_VARYING_VECTORS'
	show'GL_MAX_VARYING_FLOATS'					-- gl 4 but not gles 300
	show'GL_MAX_VERTEX_ATTRIBS'
	show'GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS'
	show'GL_MAX_VERTEX_UNIFORM_COMPONENTS'
	show'GL_MAX_VERTEX_UNIFORM_VECTORS'
	show'GL_MAX_VERTEX_OUTPUT_COMPONENTS'
	show'GL_MAX_VERTEX_UNIFORM_BLOCKS'
	show'GL_MAX_VIEWPORT_DIMS'
	show'GL_NUM_EXTENSIONS'
	show'GL_NUM_SHADER_BINARY_FORMATS'
	show'GL_PACK_ALIGNMENT'
	show'GL_PACK_IMAGE_HEIGHT'			-- gl 4 but not gles 300
	show'GL_PACK_LSB_FIRST'			-- gl 4 but not gles 300
	show'GL_PACK_ROW_LENGTH'
	show'GL_PACK_SKIP_IMAGES'			-- gl 4 but not gles 300
	show'GL_PACK_SKIP_PIXELS'
	show'GL_PACK_SKIP_ROWS'
	show'GL_PACK_SWAP_BYTES'			-- gl 4 but not gles 300
	show'GL_PRIMITIVE_RESTART_INDEX'			-- gl 4 but not gles 300
	show'GL_NUM_PROGRAM_BINARY_FORMATS'
	show'GL_PROGRAM_BINARY_FORMATS'
	show'GL_PROGRAM_POINT_SIZE'			-- gl 4 but not gles 300
	show'GL_PROVOKING_VERTEX'			-- gl 4 but not gles 300
	show'GL_PRIMITIVE_RESTART_FIXED_INDEX'	-- gles 300 but not gl 4
	show'GL_RASTERIZER_DISCARD'	-- gles 300 but not gl 4
	show'GL_READ_BUFFER'
	show'GL_SAMPLE_ALPHA_TO_COVERAGE'	-- gles 300 but not gl 4
	show'GL_SAMPLE_BUFFERS'
	show'GL_SAMPLE_COVERAGE_VALUE'
	show'GL_SAMPLE_COVERAGE_INVERT'
	show'GL_SAMPLE_COVERAGE'		-- gles 300 but not gl 4
	show'GL_SAMPLE_MASK_VALUE'	-- gl 4 but not gles 300
	show'GL_SAMPLES'
	show'GL_SCISSOR_BOX'
	show'GL_SCISSOR_TEST'
	show'GL_SHADER_BINARY_FORMATS'	-- gles 300 but not gl 4
	show'GL_SHADER_COMPILER'
	show'GL_SHADER_STORAGE_BUFFER_OFFSET_ALIGNMENT'	-- gl 4 but not gles 300
	local maxShaderStorageBufferBindings = show'GL_MAX_SHADER_STORAGE_BUFFER_BINDINGS'	-- gl 4 but not gles 300
	if type(maxShaderStorageBufferBindings) == 'number' then
		for i=0,maxShaderStorageBufferBindings-1 do
			show('GL_SHADER_STORAGE_BUFFER_BINDING', i)	-- can be indexed, but whats the index range?
		end
		for i=0,maxShaderStorageBufferBindings-1 do
			show('GL_SHADER_STORAGE_BUFFER_START', i)	-- can be indexed, but whats the index range?
		end
		for i=0,maxShaderStorageBufferBindings-1 do
			show('GL_SHADER_STORAGE_BUFFER_SIZE', i)	-- can be indexed, but whats the index range?
		end
	end
	show'GL_STENCIL_BACK_FAIL'
	show'GL_STENCIL_BACK_FUNC'
	show'GL_STENCIL_BACK_PASS_DEPTH_FAIL'
	show'GL_STENCIL_BACK_PASS_DEPTH_PASS'
	show'GL_STENCIL_BACK_REF'
	show'GL_STENCIL_BACK_VALUE_MASK'
	show'GL_STENCIL_BACK_WRITEMASK'
	show'GL_STENCIL_CLEAR_VALUE'
	show'GL_STENCIL_FAIL'
	show'GL_STENCIL_FUNC'
	show'GL_STENCIL_PASS_DEPTH_FAIL'
	show'GL_STENCIL_PASS_DEPTH_PASS'
	show'GL_STENCIL_REF'
	show'GL_STENCIL_TEST'
	show'GL_STENCIL_VALUE_MASK'
	show'GL_STENCIL_WRITEMASK'
	show'GL_STEREO'								-- gl 4 but not gles 300
	show'GL_TEXTURE_BINDING_1D'	-- gl 4 but not gles 300
	show'GL_TEXTURE_BINDING_1D_ARRAY'	-- gl 4 but not gles 300
	show'GL_TEXTURE_BINDING_2D'
	show'GL_TEXTURE_BINDING_2D_ARRAY'
	show'GL_TEXTURE_BINDING_2D_MULTISAMPLE'	-- gl 4 but not gles 300
	show'GL_TEXTURE_BINDING_2D_MULTISAMPLE_ARRAY'	-- gl 4 but not gles 300
	show'GL_TEXTURE_BINDING_3D'
	show'GL_TEXTURE_BINDING_BUFFER'	-- gl 4 but not gles 300
	show'GL_TEXTURE_BINDING_CUBE_MAP'
	show'GL_TEXTURE_BINDING_RECTANGLE'
	show'GL_TEXTURE_COMPRESSION_HINT'
	show'GL_TIMESTAMP'
	-- which is the max for these?
	local maxTransformFeedbackBuffers = show'GL_MAX_TRANSFORM_FEEDBACK_BUFFERS'
	if type(maxTransformFeedbackBuffers) == 'number' then
		for i=0,maxTransformFeedbackBuffers-1 do
			show('GL_TRANSFORM_FEEDBACK_BUFFER_BINDING', i)
		end
	end
	if type(maxShaderStorageBufferBindings) == 'number' then
		for i=0,maxShaderStorageBufferBindings-1 do
			show('GL_TRANSFORM_FEEDBACK_BUFFER_START', i)
		end
		for i=0,maxShaderStorageBufferBindings-1 do
			show('GL_TRANSFORM_FEEDBACK_BUFFER_SIZE', i)
		end
		for i=0,maxShaderStorageBufferBindings-1 do
			show('GL_TRANSFORM_FEEDBACK_BINDING', i)	-- gles 300 but not gl 4
		end
		show'GL_TRANSFORM_FEEDBACK_ACTIVE'	-- gles 300 but not gl 4
		show'GL_TRANSFORM_FEEDBACK_PAUSED'	-- gles 300 but not gl 4
		-- which is the max for these?
		-- is it the max # uniforms of the currently bound shader? idk?
		for i=0,maxShaderStorageBufferBindings-1 do
			show('GL_UNIFORM_BUFFER_BINDING', i)
		end
		for i=0,maxShaderStorageBufferBindings-1 do
			show('GL_UNIFORM_BUFFER_SIZE', i)
		end
		for i=0,maxShaderStorageBufferBindings-1 do
			show('GL_UNIFORM_BUFFER_START', i)
		end
		if version >= 4.3 then
			-- TODO max is specific to bound vertex, so won't be anything useful here ...
			local currentProgramMaxVertexAttributes = 0
			for i=0,currentProgramMaxVertexAttributes-1 do
				show('GL_VERTEX_BINDING_DIVISOR', i)	-- gl 4 but not gles 300
				show('GL_VERTEX_BINDING_OFFSET', i)	-- gl 4 but not gles 300
				show('GL_VERTEX_BINDING_STRIDE', i)	-- gl 4 but not gles 300
				show('GL_VERTEX_BINDING_BUFFER', i)	-- gl 4 but not gles 300
			end
		end
	end
	show'GL_UNIFORM_BUFFER_OFFSET_ALIGNMENT'
	show'GL_UNPACK_ALIGNMENT'
	show'GL_UNPACK_IMAGE_HEIGHT'
	show'GL_UNPACK_LSB_FIRST'		-- gl 4 but not gles 300
	show'GL_UNPACK_ROW_LENGTH'
	show'GL_UNPACK_SKIP_IMAGES'
	show'GL_UNPACK_SKIP_PIXELS'
	show'GL_UNPACK_SKIP_ROWS'
	show'GL_UNPACK_SWAP_BYTES'		-- gl 4 but not gles 300
	show'GL_VERTEX_ARRAY_BINDING'

	if version >= 4.1 then
		print'GL version >= 4.1:'
		show'GL_VIEWPORT'
		local maxViewports = show'GL_MAX_VIEWPORTS'
		if type(maxViewports) ~= 'string' then
			for i=0,maxViewports-1 do
				show('GL_VIEWPORT', i)
			end
		end
		show'GL_VIEWPORT_SUBPIXEL_BITS'
		show'GL_VIEWPORT_BOUNDS_RANGE'
		show'GL_LAYER_PROVOKING_VERTEX'
		show'GL_VIEWPORT_INDEX_PROVOKING_VERTEX'

		show'GL_NUM_SHADER_BINARY_FORMATS'
		show'GL_SHADER_BINARY_FORMATS'
	end
	if version >= 4.2 then
		print'GL version >= 4.2:'
		show'GL_MAX_VERTEX_ATOMIC_COUNTERS'
		show'GL_MAX_TESS_CONTROL_ATOMIC_COUNTERS'
		show'GL_MAX_TESS_EVALUATION_ATOMIC_COUNTERS'
		show'GL_MAX_GEOMETRY_ATOMIC_COUNTERS'
		show'GL_MAX_FRAGMENT_ATOMIC_COUNTERS'
		show'GL_MIN_MAP_BUFFER_ALIGNMENT'
	end
	if version >= 4.3 then
		print'GL version >= 4.3:'
		show'GL_MAX_ELEMENT_INDEX'
		show'GL_MAX_COMPUTE_UNIFORM_BLOCKS'
		show'GL_MAX_COMPUTE_TEXTURE_IMAGE_UNITS'
		show'GL_MAX_COMPUTE_UNIFORM_COMPONENTS'
		show'GL_MAX_COMPUTE_ATOMIC_COUNTERS'
		show'GL_MAX_COMPUTE_ATOMIC_COUNTER_BUFFERS'
		show'GL_MAX_COMBINED_COMPUTE_UNIFORM_COMPONENTS'
		show'GL_MAX_COMPUTE_WORK_GROUP_INVOCATIONS'
		for i=0,2 do
			show('GL_MAX_COMPUTE_WORK_GROUP_COUNT', i)
		end
		for i=0,2 do
			show('GL_MAX_COMPUTE_WORK_GROUP_SIZE', i)
		end
		show'GL_DISPATCH_INDIRECT_BUFFER_BINDING'
		show'GL_MAX_DEBUG_GROUP_STACK_DEPTH'
		show'GL_DEBUG_GROUP_STACK_DEPTH'
		show'GL_MAX_LABEL_LENGTH'
		show'GL_MAX_UNIFORM_LOCATIONS'
		show'GL_MAX_FRAMEBUFFER_WIDTH'
		show'GL_MAX_FRAMEBUFFER_HEIGHT'
		show'GL_MAX_FRAMEBUFFER_LAYERS'
		show'GL_MAX_FRAMEBUFFER_SAMPLES'
		show'GL_MAX_VERTEX_SHADER_STORAGE_BLOCKS'
		show'GL_MAX_TESS_CONTROL_SHADER_STORAGE_BLOCKS'

		show'GL_MAX_TESS_EVALUATION_SHADER_STORAGE_BLOCKS'
		show'GL_MAX_GEOMETRY_SHADER_STORAGE_BLOCKS'
		show'GL_MAX_FRAGMENT_SHADER_STORAGE_BLOCKS'
		show'GL_MAX_COMPUTE_SHADER_STORAGE_BLOCKS'
		show'GL_TEXTURE_BUFFER_OFFSET_ALIGNMENT'
		show'GL_MAX_VERTEX_ATTRIB_RELATIVE_OFFSET'
		show'GL_MAX_VERTEX_ATTRIB_BINDINGS'
	end


	do
		local glSafeCall = require 'gl.error'.glSafeCall
assert(require 'gl.report''after globals')
		local rangePtr = ffi.new'GLint[2]'
		local precisionPtr = ffi.new'GLint[1]'
		for _,shaderTypeParamName in ipairs{
			'GL_VERTEX_SHADER',
			'GL_FRAGMENT_SHADER',
			'GL_GEOMETRY_SHADER',
			'GL_TESS_EVALUATION_SHADER',
			'GL_TESS_CONTROL_SHADER',
			'GL_COMPUTE_SHADER',
		} do
			local shaderTypeParamValue = op.safeindex(gl, shaderTypeParamName)
			if shaderTypeParamValue then
				print(shaderTypeParamName..' precision:')
				for _,precParamName in ipairs{
					'GL_LOW_FLOAT', 'GL_MEDIUM_FLOAT', 'GL_HIGH_FLOAT',
					'GL_LOW_INT', 'GL_MEDIUM_INT', 'GL_HIGH_INT',
				} do
					local precParamValue = op.safeindex(gl, precParamName)
					if not precParamValue then
						print(shaderType, precParamName..' not defined')
					else
						local success, msg = glSafeCall('glGetShaderPrecisionFormat', shaderTypeParamValue, precParamValue, rangePtr, precisionPtr)
						if not success then
							print(shaderTypeParamName..' failed: '..msg)
						else
require 'gl.report' 'gl.glGetShaderPrecisionFormat'
							print(shaderTypeParamName, precParamName, err and '...error' or 'range={'..rangePtr[0]..', '..rangePtr[1]..'},\tprecision='..precisionPtr[0])
						end
					end
				end
			end
		end
assert(require 'gl.report' 'shader precision')
	end

	local str = glGlobal:get'GL_EXTENSIONS'	-- how come sometimes this gives me invalid enum, sometimes gives me null
	print('GL_EXTENSIONS', not str and 'null' or '\n\t'..(str:trim():split' ':sort():concat'\n\t'))

	self:requestExit()
	print'done'
end
return App():run()
