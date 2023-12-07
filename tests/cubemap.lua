#!/usr/bin/env luajit
-- put this here or in gl ? or in imguiapp ?
local ffi = require 'ffi'
local gl = require 'gl'
local GLTexCube = require 'gl.texcube'

--local App = require 'glapp.orbit'()
local App = require 'imguiapp.withorbit'()

App.title = "Spinning Triangle"

-- TODO provide your own skybox
local base = ...
--base = base or '../../seashell/beach-skyboxes/HeartInTheSand/'	-- uses pos/neg xyz
base = base or '../../seashell/cloudy/bluecloud_'	-- uses ft bk up dn rt lf

App.viewDist = 1e-7

function App:initGL(...)
	App.super.initGL(self, ...)
	
	self.tex = GLTexCube{
		--[[
		filenames = {
			base..'posx.jpg',
			base..'negx.jpg',
			base..'posy.jpg',
			base..'negy.jpg',
			base..'posz.jpg',
			base..'negz.jpg',
		},
		--]]
		-- [[
		filenames = {
			base..'ft.jpg',
			base..'bk.jpg',
			base..'up.jpg',
			base..'dn.jpg',
			base..'rt.jpg',
			base..'lf.jpg',
		},	
		--]]
		wrap={
			s=gl.GL_CLAMP_TO_EDGE,
			t=gl.GL_CLAMP_TO_EDGE,
			r=gl.GL_CLAMP_TO_EDGE,
		},
		magFilter = gl.GL_LINEAR,
		minFilter = gl.GL_LINEAR,
	}:unbind()
	
	gl.glClearColor(0, 0, 0, 0)
	gl.glEnable(gl.GL_DEPTH_TEST)
end

-- notice that the order matches global 'sides'
cubeFaces = {
	{5,7,3,1};		-- <- each value has the x,y,z in the 0,1,2 bits (off = 0, on = 1)
	{6,4,0,2};
	{2,3,7,6};
	{4,5,1,0};
	{6,7,5,4};
	{0,1,3,2};
}
local vec2d = require 'vec-ffi.vec2d'
local uvs = {
	vec2d(0,0),
	vec2d(1,0),
	vec2d(1,1),
	vec2d(0,1),
}


function App:update(...)
	App.super.update(self, ...)

	gl.glClear(bit.bor(gl.GL_COLOR_BUFFER_BIT, gl.GL_DEPTH_BUFFER_BIT))

	self.tex
		:enable()
		:bind()
	gl.glBegin(gl.GL_QUADS)
	local s = 1
	for _,face in ipairs(cubeFaces) do
		for _,i in ipairs(face) do
			local x = bit.band(i, 1)
			local y = bit.band(bit.rshift(i, 1), 1)
			local z = bit.band(bit.rshift(i, 2), 1)
			gl.glTexCoord3d(s*(x*2-1),s*(y*2-1),s*(z*2-1))
			gl.glVertex3d(s*(x*2-1),s*(y*2-1),s*(z*2-1))
		end
	end
	gl.glEnd()
	self.tex
		:unbind()
		:disable()
end

return App():run()
