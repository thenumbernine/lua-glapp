package = "glapp"
version = "dev-1"
source = {
	url = "git+https://github.com/thenumbernine/lua-glapp.git"
}
description = {
	summary = "OpenGL application wrapper for LuaJIT.",
	detailed = "OpenGL application wrapper for LuaJIT.",
	homepage = "https://github.com/thenumbernine/lua-glapp",
	license = "MIT"
}
dependencies = {
	"lua >= 5.1"
}
build = {
	type = "builtin",
	modules = {
		["glapp"] = "glapp.lua",
		["glapp.orbit"] = "orbit.lua",
		["glapp.tests.test"] = "tests/test.lua",
		["glapp.tests.version"] = "tests/version.lua",
		["glapp.view"] = "view.lua"
	},
}
