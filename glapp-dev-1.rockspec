package = "glapp"
version = "dev-1"
source = {
	url = "git+https://github.com/thenumbernine/lua-glapp"
}
description = {
	summary = "OpenGL application wrapper for LuaJIT.",
	detailed = "OpenGL application wrapper for LuaJIT.",
	homepage = "https://github.com/thenumbernine/lua-glapp",
	license = "MIT"
}
dependencies = {
	"lua ~> 5.1"
}
build = {
	type = "builtin",
	modules = {
		["glapp"] = "glapp.lua",
		["glapp.mouse"] = "mouse.lua",
		["glapp.orbit"] = "orbit.lua",
		["glapp.tests.compute"] = "tests/compute.lua",
		["glapp.tests.compute-spirv"] = "tests/compute-spirv.lua",
		["glapp.tests.cubemap"] = "tests/cubemap.lua",
		["glapp.tests.events"] = "tests/events.lua",
		["glapp.tests.info"] = "tests/info.lua",
		["glapp.tests.minimal"] = "tests/minimal.lua",
		["glapp.tests.pointtest"] = "tests/pointtest.lua",
		["glapp.tests.test"] = "tests/test.lua",
		["glapp.tests.test_es"] = "tests/test_es.lua",
		["glapp.tests.test_es_directcalls"] = "tests/test_es_directcalls.lua",
		["glapp.tests.test_tex"] = "tests/test_tex.lua",
		["glapp.tests.test_vertexattrib"] = "tests/test_vertexattrib.lua",
		["glapp.view"] = "view.lua"
	},
}
