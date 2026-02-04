#!/usr/bin/env luajit
local cmdline = require 'ext.cmdline'(...)
local sdl = require 'sdl'
local gl = require 'gl.setup'(cmdline.gl)
local GLSceneObject = require 'gl.sceneobject'

local App = require 'glapp.orbit'()
App.viewDist = 3

function App:initGL()
	self.globj = GLSceneObject{
		program = {
			version = 'latest',
			precision = 'best',
			vertexCode = [[
layout(location=0) in vec3 vertex;
layout(location=0) out vec3 vertexv;

layout(location=0) uniform mat4 mvProjMat;

void main() {
	vertexv = vertex;
	gl_Position = mvProjMat * vec4(vertex, 1.);
}
]],
			geometryCode = [[
// I don't suppose tesselation can be specified by uniform ... probably not when tesselation shaders exist
#define MAX_TESS 4

layout(triangles) in;
layout(triangle_strip, 
	max_vertices=MAX_TESS*MAX_TESS*3
) out;

layout(location=0) in vec3 vertexv[];
layout(location=0) out vec3 colorg;

layout(location=0) uniform mat4 mvProjMat;

void emitVtx(vec3 c, vec3 v) {
	colorg = c;//v;
	gl_Position = mvProjMat * vec4(v, 1.);
	EmitVertex();
}

// triBasis[0] = v1-v0, triBasis[1] = v2-v0, triBasis[2] = v0
vec3 getVertex(ivec2 ij, mat3 triBasis) {
	float fi = float(ij.x) / float(MAX_TESS);
	float fj = float(ij.y) / float(MAX_TESS);
	vec3 v = triBasis[0] * fi + triBasis[1] * fj + triBasis[2];
	return v;
}

void emitTri(ivec2 ij0, ivec2 ij1, ivec2 ij2, mat3 triBasis) {
	emitVtx(vec3(ij0, float(MAX_TESS))/float(MAX_TESS), getVertex(ij0, triBasis));
	emitVtx(vec3(ij1, float(MAX_TESS))/float(MAX_TESS), getVertex(ij1, triBasis));
	emitVtx(vec3(ij2, float(MAX_TESS))/float(MAX_TESS), getVertex(ij2, triBasis));
	EndPrimitive();
}

void main() {
	// compare inner product between vertices
	// subdivide accordingly
	// or use pixel length somehow

	float dot01 = dot(vertexv[0], vertexv[1]);
	float dot02 = dot(vertexv[0], vertexv[2]);
	float dot12 = dot(vertexv[1], vertexv[2]);
	float mindot = min(dot01, min(dot02, dot12));
	
	// TODO convert to arclength or something and determine subdivision amount
	const float dotAngleThreshold = 1.;
	if (mindot < dotAngleThreshold) {
		mat3 triBasis;
		triBasis[0] = vertexv[1] - vertexv[0];
		triBasis[1] = vertexv[2] - vertexv[0];
		triBasis[2] = vertexv[0];
		for (int i = 0; i < MAX_TESS; ++i) {
			for (int j = 0; j < MAX_TESS-i; ++j) {
				emitTri(ivec2(i,j), ivec2(i+1, j), ivec2(i,j+1), triBasis);
				if (i+1 < MAX_TESS && j < MAX_TESS-(i+1)) {
					emitTri(ivec2(i,j+1), ivec2(i+1, j), ivec2(i+1,j+1), triBasis);
				}
			}
		}
	} else {
		// emit as is
		for (int i = 0; i < 3; ++i) {
			gl_Position = gl_in[i].gl_Position;
			colorg = vertexv[i];
			EmitVertex();
		}
		EndPrimitive();
	}
}
]],
			fragmentCode = [[
layout(location=0) in vec3 colorg;
layout(location=0) out vec4 fragColor;
void main() {
	fragColor = vec4(
		//normalize(colorg) * .4 + .6,
		colorg,
		1.);
}
]],
		},
		vertexes = {
			dim = 3,
			data = {
				0, 0, 1,
				0, math.sqrt(8/9), -1 / 3,
				math.sqrt(2/3), -math.sqrt(2/9), -1 / 3,
				-math.sqrt(2/3), -math.sqrt(2/9), -1 / 3,
			},
		},
		geometry = {
			mode = gl.GL_TRIANGLES,
			indexes = {
				data = {
					2,1,0,
					0,1,3,
					3,2,0,
					1,2,3,
				},
			},
		},
		uniforms = {
			mvProjMat = self.view.mvProjMat.ptr,
		},
	}

	gl.glEnable(gl.GL_DEPTH_TEST)
	gl.glEnable(gl.GL_CULL_FACE)
	gl.glLineWidth(2)
end

local useLines
function App:update()
	App.super.update(self)
	gl.glClear(bit.bor(gl.GL_COLOR_BUFFER_BIT, gl.GL_DEPTH_BUFFER_BIT))
	gl.glPolygonMode(gl.GL_FRONT_AND_BACK, useLines and gl.GL_LINE or gl.GL_FILL)
	self.globj:draw()
end

function App:event(e)
	if e[0].type == sdl.SDL_EVENT_MOUSE_BUTTON_DOWN then
		useLines = not useLines
	end
	App.super.event(self, e)
end

return App():run()
