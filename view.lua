local class = require 'ext.class'
local vec3d = require 'vec-ffi.vec3d'
local quatd = require 'vec-ffi.quatd'
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
		self.view.pos.z = self.viewDist or self.view.pos.z
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

local function unpack(t)
	return (t.unpack or table.unpack)(t)
end

function View:init(args)
	if args then
		self.pos = vec3d(unpack(args.pos))
		self.orbit = vec3d(unpack(args.orbit))
		self.angle = quatd(unpack(args.angle))
	else
		self.pos = vec3d(0,0,10)
		self.orbit = vec3d(0,0,0)	-- orbit center
		self.angle = quatd(0,0,0,1)
	end
end

function View:setup(aspectRatio)
	self:setupProjection(aspectRatio)
	self:setupModelView()
end

-- get the arguments for glFrustum / glOrtho
function View:getBounds(aspectRatio)
	if not self.ortho then
		local tanFovY = math.tan(math.rad(self.fovY / 2))
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
	gl.glRotated(aa.w, aa.x, aa.y, aa.z)
	gl.glTranslated(-self.pos.x, -self.pos.y, -self.pos.z)
end

return View
