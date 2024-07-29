#!/usr/bin/env luajit
local ffi = require 'ffi'
local gl = require 'gl.setup'(... or 'OpenGL')
local GLProgram = require 'gl.program'
local GLArrayBuffer = require 'gl.arraybuffer'
local GLVertexArray = require 'gl.vertexarray'

-- Create transform feedback buffer
-- TODO create it as an ArrayBuffer and use as target=TRANSFORM_FEEDBACK_BUFFER?
-- or create it as TRANSFORM_FEEDBACK_BUFFER?
-- or does it make a difference?
local GLTransformFeedbackBuffer = require 'gl.transformfeedbackbuffer'

-- from https://open.gl/feedback
local App = require 'glapp':subclass()

function App:initGL()
	local program = GLProgram{
		version = 'latest',
		precision = 'best',
		vertexCode = [[
in float inValue;
out float outValue;
void main() {
	outValue = sqrt(inValue);
}
]],
		transformFeedback = {
			'outValue',
			mode = 'interleaved',	-- TODO default mode?
		},
	}	-- leave bound

	local data = ffi.new('GLfloat[5]', { 1, 2, 3, 4, 5 })
	local inBuffer = GLArrayBuffer{
		size = ffi.sizeof'GLfloat' * 5,
		usage = gl.GL_STATIC_DRAW,
		data = data,
	}:unbind()

	local vao = GLVertexArray{
		program = program,
		attrs = {
			inValue = {
				buffer = inBuffer,
			},
		},
	}:bind()	-- unlike everything else, VAO ctors unbound (since if no attrs are provided it doenst even have to bind to begin with)

	local outBuffer = GLTransformFeedbackBuffer{
		size = ffi.sizeof'GLfloat' * 5,
		usage = gl.GL_STATIC_READ,
	}	-- leave bound

	-- Perform feedback transform
	gl.glEnable(gl.GL_RASTERIZER_DISCARD)

print(require 'ext.tolua'{
	attrs = program.attrs,
	varyings = program.varyings,
})
	outBuffer:bindBase()	-- () == (0) == layout(binding=...) of our one varying (is it? is binding and location the same?)

	gl.glBeginTransformFeedback(gl.GL_POINTS)
	gl.glDrawArrays(gl.GL_POINTS, 0, 5)
	gl.glEndTransformFeedback()

	gl.glDisable(gl.GL_RASTERIZER_DISCARD)
	gl.glFlush()

	-- Fetch and print results
	-- not available in GLES ... so how do you read data in GLES?
	--[[
	local feedback = ffi.new('GLfloat[5]')
	gl.glGetBufferSubData(gl.GL_TRANSFORM_FEEDBACK_BUFFER, 0, ffi.sizeof(feedback), feedback)
	print(("%f %f %f %f %f"):format(feedback[0], feedback[1], feedback[2], feedback[3], feedback[4]))
	--]]
	-- [[ ... but webgl2 does have glGetBufferData ... but gles3 doesn't ...
	-- but gles does have glMapBufferRange ... but webgl doesn't ...
	local feedback = ffi.cast('GLfloat*', gl.glMapBufferRange(gl.GL_TRANSFORM_FEEDBACK_BUFFER, 0, 5 * ffi.sizeof'GLfloat', gl.GL_MAP_READ_BIT))
	print('feedback', feedback)
	assert(feedback ~= nil)
	print(("%f %f %f %f %f"):format(feedback[0], feedback[1], feedback[2], feedback[3], feedback[4]))
	gl.glUnmapBuffer(gl.GL_TRANSFORM_FEEDBACK_BUFFER)
	--]]
	
	self:requestExit()
end

return App():run()
