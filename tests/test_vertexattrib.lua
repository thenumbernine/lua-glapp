#!/usr/bin/env luajit
require 'ext'
local ffi = require 'ffi'
local glver = cmdline.gl	-- "gl=OpenGLES3" to test GLES3
local gl = require 'gl.setup' (glver)
local glreport = require 'gl.report'
local GLVertexArray = require 'gl.vertexarray'
local GLAttribute = require 'gl.attribute'
--[[
is vertexattribpointer and enablevertexattrib per-shader or global?

uniform state is per-shader
texture state (glBindTexture, glEnable(GL_TEXTURE*), etc) is global

i'd guess attribute was per-shader bcause attrs and uniforsm go hadn in hand

but attr functionality (enableclientstate etc) has been around long before shaders
and might be legacy behavior to when *everything* was global state

same qustion but when VAO's are used?
VAO's are in GL and GLES3 (but not GLES2) and WebGL2 (but not WebGL1)
so relying on this functionality is meh for portability...

https://developer.mozilla.org/en-US/docs/Web/API/WebGLVertexArrayObject
mozilla webgl2 docs say VAOs save bindbuffer and vertexattribpointer
so i.g. without VAO these calls are global, but with VAO these calls are state
--]]
local GLProgram = require 'gl.program'
local App = require 'glapp':subclass()
function App:initGL()

	local glslheader = '#version 320 es\n'
		..'precision highp float;\n'
	-- minimal shader
	local shaders = range(2):mapi(function()
		return GLProgram{
			vertexCode = glslheader..[[
layout(location=0) in vec2 vertex;
out vec2 texcoordv;
void main() {
	texcoordv = vertex;
	gl_Position = vec4(vertex, 0., 1.);
}
]],
			fragmentCode = glslheader..[[
in vec2 texcoordv;
out vec4 fragColor;
void main() {
	fragColor = vec4(texcoordv, 0., 1.);
}
]],
			-- creates a vao per shader by default unless otherwise stated..
			createVAO = false,
		}
			:useNone()
	end)

	for i,sh in ipairs(shaders) do
		print('shader '..i)
		print(tolua(sh.attrs))
	end

	-- enable/disable, bind/unbind, and check state with dif shaders bound

	-- is 'enable' saved per-shader?
	gl.glEnableVertexAttribArray(0)
	
	-- hmm next question, how to get its status
	-- typically glGetVertexAttrib is for the currently-bound VAO
	-- but if no VAO is bound, does it return global-state enableVerteAttribArray's?
	-- glGetVertexAttrib docs are great.
	-- 1st arg: "vertex attribute parameter to be queried"
	-- 2nd arg: "vertex attribute parameter to be queried"
	--GLVertexArray:get'GL_
	-- more mysteries to be solved.
	-- [[

	print("shaders[1].attrs.vertex:get'GL_VERTEX_ATTRIB_ARRAY_ENABLED'", shaders[1].attrs.vertex:get'GL_VERTEX_ATTRIB_ARRAY_ENABLED')
	--]]
	-- this could double as this in my API
	-- but I think I'm skipipng the 1st arg ...
	--print('GL_VERTEX_ATTRIB_ARRAY_ENABLED', GLVertexAttrib:get'GL_VERTEX_ATTRIB_ARRAY_ENABLED')

	-- now repeat with differnt shaders+differnt VAOs bound


	self:requestExit()
end
return App():run()
