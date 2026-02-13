package = "app3d"
version = "dev-1"
source = {
	url = "git+https://github.com/thenumbernine/lua-app3d"
}
description = {
	summary = "3D-application support classes.",
	detailed = "3D-application support classes.",
	homepage = "https://github.com/thenumbernine/lua-app3d",
	license = "MIT"
}
dependencies = {
	"lua >= 5.1"
}
build = {
	type = "builtin",
	modules = {
		["app3d.orbit"] = "orbit.lua",
		["app3d.view"] = "view.lua"
	},
}
