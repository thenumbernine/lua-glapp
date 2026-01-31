local ffi = require 'ffi'
local class = require 'ext.class'
local vec3d = require 'vec-ffi.vec3d'
local quatd = require 'vec-ffi.quatd'

local float = ffi.typeof'float'

local View = class()

View.znear = .1
View.zfar = 100
View.ortho = false
View.orthoSize = 10	-- TODO use fovY somehow?
View.fovY = 90

-- set this to 'true' on the class before construction , or as a ctor arg
View.useGLMatrixMode = false

-- static method applied to GLApp classes
function View.apply(cl)
	cl = class(cl)
	function cl:init(args, ...)
		cl.super.init(self, args, ...)
		local useGLMatrixMode
		if self.viewUseGLMatrixMode ~= nil then
			useGLMatrixMode = self.viewUseGLMatrixMode
		end
		if args and args.viewUseGLMatrixMode ~= nil then
			useGLMatrixMode = args.viewUseGLMatrixMode
		end
		self.view = View{
			useGLMatrixMode = useGLMatrixMode,
		}
		self.view.pos.z = self.viewDist or self.view.pos.z
	end
	function cl:update(...)
		self.view:setup(self.width / self.height)
		local superUpdate = cl.super.update
		if superUpdate then
			superUpdate(self, ...)
		end
	end

	-- let orbit know this class has a view, so if orbit doesn't find this flag it can call View.apply itself
	cl.viewApplied = true

	return cl
end

local function unpack(t)
	return (t.unpack or table.unpack)(t)
end

function View:init(args)
	self.pos = vec3d(0,0,10)
	self.orbit = vec3d(0,0,0)	-- orbit center
	self.angle = quatd(0,0,0,1)
	if args then
		if args.pos then self.pos:set(unpack(args.pos)) end
		if args.orbit then self.orbit:set(unpack(args.orbit)) end
		if args.angle then self.angle:set(unpack(args.angle)):normalize(self.angle) end
		self.znear = args.znear
		self.zfar = args.zfar
		if args.ortho ~= nil then self.ortho = args.ortho end
		self.orthoSize = args.orthoSize
		self.fovY = args.fovY
		if args.useGLMatrixMode ~= nil then
			self.useGLMatrixMode = args.useGLMatrixMode
		end
	end

	if not self.useGLMatrixMode then
		local vec4x4f = require 'vec-ffi.vec4x4f'
		self.projMat = vec4x4f():setIdent()
		self.mvMat = vec4x4f():setIdent()

		-- TODO do I even need this?  not for GL at least ...
		self.mvProjMat = vec4x4f():setIdent()
	end
end

function View:setup(aspectRatio)
	self:setupProjection(aspectRatio)
	self:setupModelView()
	if not self.useGLMatrixMode then
		self.mvProjMat:mul4x4(self.projMat, self.mvMat)
	end
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
			-self.orthoSize * aspectRatio,
			 self.orthoSize * aspectRatio,
			-self.orthoSize,
			 self.orthoSize,
			 self.znear,
			 self.zfar
	end
end

-- don't require until you need it
local gl

function View:setupProjection(aspectRatio)
	if self.useGLMatrixMode then
		gl = gl or require 'gl'
		gl.glMatrixMode(gl.GL_PROJECTION)
		gl.glLoadIdentity()
		if not self.ortho then
			gl.glFrustum(self:getBounds(aspectRatio))
		else
			gl.glOrtho(self:getBounds(aspectRatio))
		end
	else
		if not self.ortho then
			self.projMat:setFrustum(self:getBounds(aspectRatio))
		else
			self.projMat:setOrtho(self:getBounds(aspectRatio))
		end
	end
end

function View:setupModelView()
	local aa = self.angle:conjugate():toAngleAxis()
	if self.useGLMatrixMode then
		gl = gl or require 'gl'
		gl.glMatrixMode(gl.GL_MODELVIEW)
		gl.glLoadIdentity()
		gl.glRotated(aa.w, aa.x, aa.y, aa.z)
		gl.glTranslated(-self.pos.x, -self.pos.y, -self.pos.z)
	else
		self.mvMat:setRotate(math.rad(aa.w), aa.x, aa.y, aa.z)
			:applyTranslate(-self.pos.x, -self.pos.y, -self.pos.z)
	end
end

return View
