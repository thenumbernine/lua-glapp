## OpenGL Application Wrapper for LuaJIT.

[![Donate via Stripe](https://img.shields.io/badge/Donate-Stripe-green.svg)](https://buy.stripe.com/00gbJZ0OdcNs9zi288)<br>
[![Donate via Bitcoin](https://img.shields.io/badge/Donate-Bitcoin-green.svg)](bitcoin:37fsp7qQKU8XoHZGRQvVzQVP8FrEJ73cSJ)<br>

### Dependencies:

- [lua-ext](https://github.com/thenumbernine/lua-ext)
- [vec-ffi-lua](https://github.com/thenumbernine/vec-ffi-lua)
- [lua-gl](https://github.com/thenumbernine/lua-gl)
- [lua-ffi-bindings](https://github.com/thenumbernine/lua-ffi-bindings) for the OpenGL, GLU, SDL bindings
- `glapp.orbit` can detect if the glapp object is a subclass of [lua-imguiapp](https://github.com/thenumbernine/lua-imguiapp) if available.

Notice that this project is the reason why I left the OpenGL parsed header code readable in my lua-ffi-bindings project.
In the event that you're using Windows (you poor, poor soul) it will sift through the GL header code and pick out the proper GL functions and load them using `wglGetProcAddress`.  
Of course if you are using any other OS on Earth then you don't have to resort to these measures.

I also added view.lua and orbit.lua to add behaviors to GLApp classes
- view.lua = View object, applied to the class via View.apply
- orbit.lua = function to apply orbit behavior
