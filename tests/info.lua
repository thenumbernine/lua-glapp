#!/usr/bin/env luajit
-- https://registry.khronos.org/OpenGL-Refpages/gl4/html/glGet.xhtml
require 'ext'
local ffi = require 'ffi'
local gl = require 'ffi.OpenGL'
class(require 'glapp', {
	initGL = function(self)
		for _,field in ipairs{
			'GL_VENDOR',
			'GL_RENDERER',
			'GL_VERSION',
		} do
			print(field, ffi.string(gl.glGetString(gl[field])))
		end


		local getterForType = {
			bool = gl.glGetBooleanv,
			int = gl.glGetIntegerv,
			float = gl.glGetFloatv,
			double = gl.glGetDoublev,
			int64_t = gl.glGetInteger64v,
		}

		local getterIndexedForType = {
			bool = gl.glGetBooleani_v,
			int = gl.glGetIntegeri_v,
			float = gl.glGetFloati_v,
			double = gl.glGetDoublei_v,
			int64_t = gl.glGetInteger64i_v,
		}

		local function getTypeN(name, ctype, count)
			local v = ffi.new(ctype..'[?]', count)
			local getter = assert(getterForType[ctype])
			getter(assert(gl[name]), v)
			return range(0,count-1):mapi(function(i) return v[i] end):unpack()
		end

		local function showTypeN(name, ...)
			local results = table.pack(getTypeN(name, ...))
			print(name..' = '..results:mapi(tostring):concat' ')
			return results:unpack()
		end

		local function showFloat(name) return showTypeN(name, 'float', 1) end
		local function showDouble(name) return showTypeN(name, 'double', 1) end

		local function showFloat2(name) return showTypeN(name, 'float', 2) end
		local function showDouble2(name) return showTypeN(name, 'double', 2) end

		local function getInt(name) return getTypeN(name, 'int', 1) end
		local function showInt(name) return showTypeN(name, 'int', 1) end

		local function getTypeNIndex(name, index, ctype, count)
			local v = ffi.new(ctype..'[?]', count)
			local getter = assert(getterIndexedForType[ctype])
			getter(assert(gl[name]), index, v)
			return range(0,count-1):mapi(function(i) return v[i] end):unpack()
		end

		local function getIntIndex(name, index) return getTypeNIndex(name, index, 'int', 1) end

		local function showTypeNIndex(name, ...)
			local results = table.pack(getTypeNIndex(name, ...))
			print(name..' = '..results:mapi(tostring):concat' ')
			return results:unpack()
		end

		local function showIntIndex(name, index)
			return showTypeNIndex(name, index, 'int', 1)
		end

		local function showInt4Index(name, index)
			return showTypeNIndex(name, index, 'int', 4)
		end

		local function showInt64Index(name, index)
			return showTypeNIndex(name, index, 'int64_t', 1)
		end

		local function showInt2(name) return showTypeN(name, 'int', 2) end
		local function showInt4(name) return showTypeN(name, 'int', 4) end

		local function showInt64(name) return showTypeN(name, 'int64_t', 1) end

		local function showInts(numName, name)
			local num = showInt(numName)
			local ints = ffi.new('int[?]', num)
			gl.glGetIntegerv(gl[name], ints)
			print(name..' = '..range(0,num-1):mapi(function(i) return ints[i] end):sort():concat' ')
		end

		local version = getInt'GL_MAJOR_VERSION' + .1 * getInt'GL_MINOR_VERSION'
		print('GL_VERSION', version)

		showInt'GL_ACTIVE_TEXTURE'
		showDouble2'GL_ALIASED_LINE_WIDTH_RANGE'
		showInt'GL_ARRAY_BUFFER_BINDING'
		showInt'GL_BLEND'
		showInt'GL_BLEND_COLOR'
		showInt'GL_BLEND_DST_ALPHA'
		showInt'GL_BLEND_DST_RGB'
		showInt'GL_BLEND_EQUATION_RGB'
		showInt'GL_BLEND_EQUATION_ALPHA'
		showInt'GL_BLEND_SRC_ALPHA'
		showInt'GL_BLEND_SRC_RGB'
		showInt'GL_COLOR_CLEAR_VALUE'
		showInt'GL_COLOR_LOGIC_OP'
		showInt'GL_COLOR_WRITEMASK'
		showInts('GL_NUM_COMPRESSED_TEXTURE_FORMATS', 'GL_COMPRESSED_TEXTURE_FORMATS')
		showInt'GL_MAX_COMBINED_SHADER_STORAGE_BLOCKS'
		showInt'GL_CONTEXT_FLAGS'
		showInt'GL_CULL_FACE'
		showInt'GL_CULL_FACE_MODE'
		showInt'GL_CURRENT_PROGRAM'
		showInt'GL_DEPTH_CLEAR_VALUE'
		showInt'GL_DEPTH_FUNC'
		showInt'GL_DEPTH_RANGE'
		showInt'GL_DEPTH_TEST'
		showInt'GL_DEPTH_WRITEMASK'
		showInt'GL_DITHER'
		showInt'GL_DOUBLEBUFFER'
		showInt'GL_DRAW_BUFFER'
		local maxDrawBuffers = showInt'GL_MAX_DRAW_BUFFERS'
		for i=0,maxDrawBuffers-1 do
--			showIntIndex('GL_DRAW_BUFFER', i)
		end
		showInt'GL_MAX_DUAL_SOURCE_DRAW_BUFFERS'
		showInt'GL_DRAW_FRAMEBUFFER_BINDING'
		showInt'GL_READ_FRAMEBUFFER_BINDING'
		showInt'GL_ELEMENT_ARRAY_BUFFER_BINDING'
		showInt'GL_FRAGMENT_SHADER_DERIVATIVE_HINT'
		showInt'GL_IMPLEMENTATION_COLOR_READ_FORMAT'
		showInt'GL_IMPLEMENTATION_COLOR_READ_TYPE'
		showInt'GL_LINE_SMOOTH'
		showInt'GL_LINE_SMOOTH_HINT'
		showInt'GL_LINE_WIDTH'
		showInt'GL_LOGIC_OP_MODE'
		showInt'GL_MAJOR_VERSION'
		showInt'GL_MINOR_VERSION'
		showInt'GL_MAX_3D_TEXTURE_SIZE'
		showInt'GL_MAX_ARRAY_TEXTURE_LAYERS'
		showInt'GL_MAX_CLIP_DISTANCES'
		showInt'GL_MAX_COLOR_TEXTURE_SAMPLES'
		showInt'GL_MAX_COMBINED_ATOMIC_COUNTERS'
		showInt'GL_MAX_COMBINED_FRAGMENT_UNIFORM_COMPONENTS'
		showInt'GL_MAX_COMBINED_GEOMETRY_UNIFORM_COMPONENTS'
		showInt'GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS'
		showInt'GL_MAX_COMBINED_UNIFORM_BLOCKS'
		showInt'GL_MAX_COMBINED_VERTEX_UNIFORM_COMPONENTS'
		showInt'GL_MAX_CUBE_MAP_TEXTURE_SIZE'
		showInt'GL_MAX_DEPTH_TEXTURE_SAMPLES'
		showInt'GL_MAX_ELEMENTS_INDICES'
		showInt'GL_MAX_ELEMENTS_VERTICES'
		showInt'GL_MAX_FRAGMENT_INPUT_COMPONENTS'
		showInt'GL_MAX_FRAGMENT_UNIFORM_COMPONENTS'
		showInt'GL_MAX_FRAGMENT_UNIFORM_VECTORS'
		showInt'GL_MAX_FRAGMENT_UNIFORM_BLOCKS'
		showInt'GL_MAX_GEOMETRY_INPUT_COMPONENTS'
		showInt'GL_MAX_GEOMETRY_OUTPUT_COMPONENTS'
		showInt'GL_MAX_GEOMETRY_TEXTURE_IMAGE_UNITS'
		showInt'GL_MAX_GEOMETRY_UNIFORM_BLOCKS'
		showInt'GL_MAX_GEOMETRY_UNIFORM_COMPONENTS'
		showInt'GL_MAX_INTEGER_SAMPLES'
		showInt'GL_MAX_PROGRAM_TEXEL_OFFSET'
		showInt'GL_MIN_PROGRAM_TEXEL_OFFSET'
		showInt'GL_MAX_RECTANGLE_TEXTURE_SIZE'
		showInt'GL_MAX_RENDERBUFFER_SIZE'
		showInt'GL_MAX_SAMPLE_MASK_WORDS'
		showInt'GL_MAX_SERVER_WAIT_TIMEOUT'
		showInt'GL_MAX_TEXTURE_BUFFER_SIZE'
		showInt'GL_MAX_TEXTURE_IMAGE_UNITS'
		showDouble'GL_MAX_TEXTURE_LOD_BIAS'
		showInt'GL_MAX_TEXTURE_SIZE'
		showInt'GL_MAX_UNIFORM_BUFFER_BINDINGS'
		showInt'GL_MAX_UNIFORM_BLOCK_SIZE'
		showInt'GL_MAX_VARYING_COMPONENTS'
		showInt'GL_MAX_VARYING_VECTORS'
		showInt'GL_MAX_VARYING_FLOATS'
		showInt'GL_MAX_VERTEX_ATTRIBS'
		showInt'GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS'
		showInt'GL_MAX_VERTEX_UNIFORM_COMPONENTS'
		showInt'GL_MAX_VERTEX_UNIFORM_VECTORS'
		showInt'GL_MAX_VERTEX_OUTPUT_COMPONENTS'
		showInt'GL_MAX_VERTEX_UNIFORM_BLOCKS'
		showInt'GL_MAX_VIEWPORT_DIMS'
		showInt'GL_NUM_EXTENSIONS'
		showInt'GL_NUM_SHADER_BINARY_FORMATS'
		showInt'GL_PACK_ALIGNMENT'
		showInt'GL_PACK_IMAGE_HEIGHT'
		showInt'GL_PACK_LSB_FIRST'
		showInt'GL_PACK_ROW_LENGTH'
		showInt'GL_PACK_SKIP_IMAGES'
		showInt'GL_PACK_SKIP_PIXELS'
		showInt'GL_PACK_SKIP_ROWS'
		showInt'GL_PACK_SWAP_BYTES'
		showInt'GL_PIXEL_PACK_BUFFER_BINDING'
		showInt'GL_PIXEL_UNPACK_BUFFER_BINDING'
		showInt'GL_POINT_FADE_THRESHOLD_SIZE'
		showInt'GL_PRIMITIVE_RESTART_INDEX'
		showInts('GL_NUM_PROGRAM_BINARY_FORMATS', 'GL_PROGRAM_BINARY_FORMATS')
		showInt'GL_PROGRAM_PIPELINE_BINDING'
		showInt'GL_PROGRAM_POINT_SIZE'
		showInt'GL_PROVOKING_VERTEX'
		showInt'GL_POINT_SIZE'
		showDouble'GL_POINT_SIZE_GRANULARITY'
		showDouble2'GL_POINT_SIZE_RANGE'
		showInt'GL_POLYGON_OFFSET_FACTOR'
		showInt'GL_POLYGON_OFFSET_UNITS'
		showInt'GL_POLYGON_OFFSET_FILL'
		showInt'GL_POLYGON_OFFSET_LINE'
		showInt'GL_POLYGON_OFFSET_POINT'
		showInt'GL_POLYGON_SMOOTH'
		showInt'GL_POLYGON_SMOOTH_HINT'
		showInt'GL_READ_BUFFER'
		showInt'GL_RENDERBUFFER_BINDING'
		showInt'GL_SAMPLE_BUFFERS'
		showDouble'GL_SAMPLE_COVERAGE_VALUE'
		showInt'GL_SAMPLE_COVERAGE_INVERT'
		showInt'GL_SAMPLE_MASK_VALUE'
		showInt'GL_SAMPLER_BINDING'
		showInt'GL_SAMPLES'
		showInt4'GL_SCISSOR_BOX'
		showInt'GL_SCISSOR_TEST'
		showInt'GL_SHADER_COMPILER'
		local maxShaderStorageBufferBindings = showInt'GL_MAX_SHADER_STORAGE_BUFFER_BINDINGS'
		showInt'GL_SHADER_STORAGE_BUFFER_OFFSET_ALIGNMENT'
		for i=0,maxShaderStorageBufferBindings-1 do
			--showIntIndex('GL_SHADER_STORAGE_BUFFER_BINDING', i)	-- can be indexed, but whats the index range?
		end
		for i=0,maxShaderStorageBufferBindings-1 do
			--showInt64Index('GL_SHADER_STORAGE_BUFFER_START', i)	-- can be indexed, but whats the index range?
		end
		for i=0,maxShaderStorageBufferBindings-1 do
			--showInt64Index('GL_SHADER_STORAGE_BUFFER_SIZE', i)	-- can be indexed, but whats the index range?
		end
		showInt'GL_SMOOTH_LINE_WIDTH_RANGE'
		showInt'GL_SMOOTH_LINE_WIDTH_GRANULARITY'
		showInt'GL_STENCIL_BACK_FAIL'
		showInt'GL_STENCIL_BACK_FUNC'
		showInt'GL_STENCIL_BACK_PASS_DEPTH_FAIL'
		showInt'GL_STENCIL_BACK_PASS_DEPTH_PASS'
		showInt'GL_STENCIL_BACK_REF'
		showInt'GL_STENCIL_BACK_VALUE_MASK'
		showInt'GL_STENCIL_BACK_WRITEMASK'
		showInt'GL_STENCIL_CLEAR_VALUE'
		showInt'GL_STENCIL_FAIL'
		showInt'GL_STENCIL_FUNC'
		showInt'GL_STENCIL_PASS_DEPTH_FAIL'
		showInt'GL_STENCIL_PASS_DEPTH_PASS'
		showInt'GL_STENCIL_REF'
		showInt'GL_STENCIL_TEST'
		showInt'GL_STENCIL_VALUE_MASK'
		showInt'GL_STENCIL_WRITEMASK'
		showInt'GL_STEREO'
		showInt'GL_SUBPIXEL_BITS'
		showInt'GL_TEXTURE_BINDING_1D'
		showInt'GL_TEXTURE_BINDING_1D_ARRAY'
		showInt'GL_TEXTURE_BINDING_2D'
		showInt'GL_TEXTURE_BINDING_2D_ARRAY'
		showInt'GL_TEXTURE_BINDING_2D_MULTISAMPLE'
		showInt'GL_TEXTURE_BINDING_2D_MULTISAMPLE_ARRAY'
		showInt'GL_TEXTURE_BINDING_3D'
		showInt'GL_TEXTURE_BINDING_BUFFER'
		showInt'GL_TEXTURE_BINDING_CUBE_MAP'
		showInt'GL_TEXTURE_BINDING_RECTANGLE'
		showInt'GL_TEXTURE_COMPRESSION_HINT'
		showInt64'GL_TIMESTAMP'
		-- which is the max for these?
		for i=0,maxShaderStorageBufferBindings-1 do
			--showIntIndex('GL_TRANSFORM_FEEDBACK_BUFFER_BINDING', i)
		end
		for i=0,maxShaderStorageBufferBindings-1 do
			--showInt64Index('GL_TRANSFORM_FEEDBACK_BUFFER_START', i)
		end
		for i=0,maxShaderStorageBufferBindings-1 do
			--showInt64Index('GL_TRANSFORM_FEEDBACK_BUFFER_SIZE', i)
		end
		-- which is the max for these?
		for i=0,maxShaderStorageBufferBindings-1 do
			--showIntIndex('GL_UNIFORM_BUFFER_BINDING', i)
		end
		for i=0,maxShaderStorageBufferBindings-1 do
			--showInt64Index('GL_UNIFORM_BUFFER_SIZE', i)
		end
		for i=0,maxShaderStorageBufferBindings-1 do
			--showInt64Index('GL_UNIFORM_BUFFER_START', i)
		end
		if version >= 4.3 then
			-- which is the max for these?
			for i=0,maxShaderStorageBufferBindings-1 do
				--showIntIndex('GL_VERTEX_BINDING_DIVISOR', i)
			end
			for i=0,maxShaderStorageBufferBindings-1 do
				--showIntIndex('GL_VERTEX_BINDING_OFFSET', i)
			end
			for i=0,maxShaderStorageBufferBindings-1 do
				--showIntIndex('GL_VERTEX_BINDING_STRIDE', i)
			end
			for i=0,maxShaderStorageBufferBindings-1 do
				--showIntIndex('GL_VERTEX_BINDING_BUFFER', i)
			end
		end
		showInt'GL_UNIFORM_BUFFER_OFFSET_ALIGNMENT'
		showInt'GL_UNPACK_ALIGNMENT'
		showInt'GL_UNPACK_IMAGE_HEIGHT'
		showInt'GL_UNPACK_LSB_FIRST'
		showInt'GL_UNPACK_ROW_LENGTH'
		showInt'GL_UNPACK_SKIP_IMAGES'
		showInt'GL_UNPACK_SKIP_PIXELS'
		showInt'GL_UNPACK_SKIP_ROWS'
		showInt'GL_UNPACK_SWAP_BYTES'
		showInt'GL_VERTEX_ARRAY_BINDING'

		if version >= 4.1 then
			print'GL version >= 4.1:'
			local maxViewports = showInt'GL_MAX_VIEWPORTS'
			for i=0,maxViewports-1 do
				--showInt4Index('GL_VIEWPORT', i)
			end
			showInt'GL_VIEWPORT_SUBPIXEL_BITS'
			showInt2'GL_VIEWPORT_BOUNDS_RANGE'
			showInt'GL_LAYER_PROVOKING_VERTEX'
			showInt'GL_VIEWPORT_INDEX_PROVOKING_VERTEX'
		end
		if version >= 4.2 then
			print'GL version >= 4.2:'
			showInt'GL_MAX_VERTEX_ATOMIC_COUNTERS'
			showInt'GL_MAX_TESS_CONTROL_ATOMIC_COUNTERS'
			showInt'GL_MAX_TESS_EVALUATION_ATOMIC_COUNTERS'
			showInt'GL_MAX_GEOMETRY_ATOMIC_COUNTERS'
			showInt'GL_MAX_FRAGMENT_ATOMIC_COUNTERS'
			showInt'GL_MIN_MAP_BUFFER_ALIGNMENT'
		end
		if version >= 4.3 then
			print'GL version >= 4.3:'
			showInt'GL_MAX_ELEMENT_INDEX'
			showInt'GL_MAX_COMPUTE_UNIFORM_BLOCKS'
			showInt'GL_MAX_COMPUTE_TEXTURE_IMAGE_UNITS'
			showInt'GL_MAX_COMPUTE_UNIFORM_COMPONENTS'
			showInt'GL_MAX_COMPUTE_ATOMIC_COUNTERS'
			showInt'GL_MAX_COMPUTE_ATOMIC_COUNTER_BUFFERS'
			showInt'GL_MAX_COMBINED_COMPUTE_UNIFORM_COMPONENTS'
			showInt'GL_MAX_COMPUTE_WORK_GROUP_INVOCATIONS'
			print('GL_MAX_COMPUTE_WORK_GROUP_COUNT', range(0,2):mapi(function(i)
				return getIntIndex('GL_MAX_COMPUTE_WORK_GROUP_COUNT', i)
			end):concat' ')
			print('GL_MAX_COMPUTE_WORK_GROUP_SIZE', range(0,2):mapi(function(i)
				return getIntIndex('GL_MAX_COMPUTE_WORK_GROUP_SIZE', i)
			end):concat' ')
			showInt'GL_DISPATCH_INDIRECT_BUFFER_BINDING'
			showInt'GL_MAX_DEBUG_GROUP_STACK_DEPTH'
			showInt'GL_DEBUG_GROUP_STACK_DEPTH'
			showInt'GL_MAX_LABEL_LENGTH'
			showInt'GL_MAX_UNIFORM_LOCATIONS'
			showInt'GL_MAX_FRAMEBUFFER_WIDTH'
			showInt'GL_MAX_FRAMEBUFFER_HEIGHT'
			showInt'GL_MAX_FRAMEBUFFER_LAYERS'
			showInt'GL_MAX_FRAMEBUFFER_SAMPLES'
			showInt'GL_MAX_VERTEX_SHADER_STORAGE_BLOCKS'
			showInt'GL_MAX_TESS_CONTROL_SHADER_STORAGE_BLOCKS'
			showInt'GL_MAX_TESS_EVALUATION_SHADER_STORAGE_BLOCKS'
			showInt'GL_MAX_GEOMETRY_SHADER_STORAGE_BLOCKS'
			showInt'GL_MAX_FRAGMENT_SHADER_STORAGE_BLOCKS'
			showInt'GL_MAX_COMPUTE_SHADER_STORAGE_BLOCKS'
			showInt'GL_TEXTURE_BUFFER_OFFSET_ALIGNMENT'
			showInt'GL_MAX_VERTEX_ATTRIB_RELATIVE_OFFSET'
			showInt'GL_MAX_VERTEX_ATTRIB_BINDINGS'
		end

		print('GL_EXTENSIONS', '\n\t'..(ffi.string(gl.glGetString(gl.GL_EXTENSIONS)):trim():split' ':sort():concat
			' '--'\n\t'
		))

		self.done = true
	end,
})():run()