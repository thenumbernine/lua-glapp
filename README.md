## OpenGL Application Wrapper for LuaJIT.

[![Donate via Stripe](https://img.shields.io/badge/Donate-Stripe-green.svg)](https://buy.stripe.com/00gbJZ0OdcNs9zi288)<br>

### Dependencies:

- [lua-ext](https://github.com/thenumbernine/lua-ext)
- [lua-ffi-bindings](https://github.com/thenumbernine/lua-ffi-bindings) for the OpenGL, SDL, etc. bindings
- [vec-ffi-lua](https://github.com/thenumbernine/vec-ffi-lua)
- [lua-gl](https://github.com/thenumbernine/lua-gl)
- [lua-sdlapp](https://github.com/thenumbernine/lua-sdlapp)
- `glapp.orbit` can detect if the glapp object is a subclass of [lua-imguiapp](https://github.com/thenumbernine/lua-imguiapp) if available.

Notice that this project is the reason why I left the OpenGL parsed header code readable in my lua-ffi-bindings project.
In the event that you're using Windows (you poor, poor soul) it will sift through the GL header code and pick out the proper GL functions and load them using `wglGetProcAddress`.  
Of course if you are using any other OS on Earth then you don't have to resort to these measures.

I also added view.lua and orbit.lua to add behaviors to GLApp classes
- view.lua = View object, applied to the class via View.apply
- orbit.lua = function to apply orbit behavior

### See it in Browser
-	[[launch]](https://thenumbernine.github.io/glapp/?dir=glapp/tests&file=test_es.lua)
	[[source]](https://thenumbernine.github.io/lua/glapp/tests/test_es.lua)
	polygon demo
-	[[launch]](https://thenumbernine.github.io/glapp/?dir=glapp/tests&file=test_tex.lua)
	[[source]](https://thenumbernine.github.io/lua/glapp/tests/test_tex.lua)
	texture demo
