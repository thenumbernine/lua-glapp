[![Donate via Stripe](https://img.shields.io/badge/Donate-Stripe-green.svg)](https://buy.stripe.com/00gbJZ0OdcNs9zi288)<br>

## 3D Application Wrapper for LuaJIT.

This used to be my OpenGL application class, but I moved that to my OpenGL library: [lua-gl](https://github.com/thenumbernine/lua-gl).

This now holds the generic 3D application classes, like view and orbit, which can be used by [lua-gl](https://github.com/thenumbernine/lua-gl), [lua-vk](https://github.com/thenumbernine/lua-vk), [lua-wgpu](https://github.com/thenumbernine/lua-wgpu), etc.

- view.lua = View object, applied to the class via View.apply
- orbit.lua = function to apply orbit behavior


<!-- is broken since my lua-ffi-fb emscripten implementation doesn't support anonymous typeof structs
### See it in Browser
-	[[launch]](https://thenumbernine.github.io/glapp/?dir=glapp/tests&file=test_es.lua)
	[[source]](https://thenumbernine.github.io/lua/glapp/tests/test_es.lua)
	polygon demo
-	[[launch]](https://thenumbernine.github.io/glapp/?dir=glapp/tests&file=test_tex.lua)
	[[source]](https://thenumbernine.github.io/lua/glapp/tests/test_tex.lua)
	texture demo
-->
