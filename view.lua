local class = require 'ext.class'
local vec3 = require 'vec.vec3'
local quat = require 'vec.quat'
local gl = require 'gl'

local View = class()

View.znear = .1
View.zfar = 100
View.ortho = false
View.orthoSize = 10
View.fovY = 90

-- static method applied to GLApp classes
function View.apply(cl)
	local cl = class(cl)
	function cl:init(...)
		cl.super.init(self, ...)
		self.view = View()
		self.view.pos[3] = self.viewDist or self.view.pos[3]
	end
	function cl:update(...)
		self.view:setup(self.width / self.height)
		local superUpdate = cl.super.update
		if superUpdate then
			superUpdate(self, ...)
		end
	end
	return cl
end

function View:init()
	self.pos = vec3(0,0,10)
	self.orbit = vec3(0,0,0)	-- orbit center
	self.angle = quat(0,0,0,1)
end

function View:setup(aspectRatio)
	self:setupProjection(aspectRatio)
	self:setupModelView()
end

-- get the arguments for glFrustum / glOrtho
function View:getBounds(aspectRatio)
	if not self.ortho then
		local tanFovY = math.tan(self.fovY / 2)
		return	
			-self.znear * aspectRatio * tanFovY,
			self.znear * aspectRatio * tanFovY,
			-self.znear * tanFovY,
			self.znear * tanFovY,
			self.znear,
			self.zfar
	else
		return
			-aspectRatio * self.orthoSize,
			aspectRatio * self.orthoSize,
			-self.orthoSize,
			self.orthoSize,
			self.znear,
			self.zfar
	end
end

function View:setupProjection(aspectRatio)
	gl.glMatrixMode(gl.GL_PROJECTION)
	gl.glLoadIdentity()
	if not self.ortho then
		gl.glFrustum(self:getBounds(aspectRatio))
	else
		gl.glOrtho(self:getBounds(aspectRatio))
	end
end

function View:setupModelView()
	gl.glMatrixMode(gl.GL_MODELVIEW)
	gl.glLoadIdentity()
	local aa = self.angle:conjugate():toAngleAxis()
	gl.glRotated(aa[4],aa[1],aa[2],aa[3])
	gl.glTranslated((-self.pos):unpack())
end

return View
