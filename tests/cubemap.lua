#!/usr/bin/env luajit
-- put this here or in gl ? or in imgui.app ?
local ffi = require 'ffi'
local gl = require 'gl'
local GLTexCube = require 'gl.texcube'

--local App = require 'glapp.orbit'()
local App = require 'imgui.appwithorbit'()

App.title = "Cubemaps"

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

-- each value has the x,y,z in the 0,1,2 bits (off = 0, on = 1)
local cubeFaces = {
	{5,7,3,1},	-- x+
	{6,4,0,2},	-- x-
	{2,3,7,6},	-- y+
	{4,5,1,0},	-- y-
	{6,7,5,4},	-- z+
	{0,1,3,2},	-- z-
}

function App:update(...)
	App.super.update(self, ...)

	gl.glClear(bit.bor(gl.GL_COLOR_BUFFER_BIT, gl.GL_DEPTH_BUFFER_BIT))

	self.tex
		:enable()
		:bind()
	gl.glEnable(gl.GL_CULL_FACE)
	gl.glBegin(gl.GL_QUADS)
	local s = 1
	-- [[ using bitvectors
	for dim=0,2 do
		for bit2 = 0,1 do	-- plus/minus side
			for bit1 = 0,1 do	-- v texcoord
				for bit0 = 0,1 do	-- u texcoord
					local i2 = bit.bor(
						bit.bxor(bit0, bit1, bit2),
						bit.lshift(bit1, 1),
						bit.lshift(bit2, 2)
					)
					-- now rotate i2 by dim
					--[=[
					local i = bit.bor(
						bit.lshift(bit.band(1, i2), (dim+0)%3),
						bit.lshift(bit.band(1, bit.rshift(i2, 1)), (dim+1)%3),
						bit.lshift(bit2, (dim+2)%3)
					)
					--]=]
					-- [=[
					local i = bit.band(7, bit.bor(
						bit.lshift(i2, dim),
						bit.rshift(i2, 3 - dim)
					))
					--]=]
					local x = bit.band(1, i)
					local y = bit.band(1, bit.rshift(i, 1))
					local z = bit.band(1, bit.rshift(i, 2))
					gl.glTexCoord3d(s*(x*2-1),s*(y*2-1),s*(z*2-1))
					gl.glVertex3d(s*(x*2-1),s*(y*2-1),s*(z*2-1))
				end
			end
		end
	end
	--]]
	--[[ using the 'cubeFaces' table
	for _,face in ipairs(cubeFaces) do
		for _,i in ipairs(face) do
			local x = bit.band(i, 1)
			local y = bit.band(bit.rshift(i, 1), 1)
			local z = bit.band(bit.rshift(i, 2), 1)
			gl.glTexCoord3d(s*(x*2-1),s*(y*2-1),s*(z*2-1))
			gl.glVertex3d(s*(x*2-1),s*(y*2-1),s*(z*2-1))
		end
	end
	--]]
	gl.glEnd()
	self.tex
		:unbind()
		:disable()
end

return App():run()
