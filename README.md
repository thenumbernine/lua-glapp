OpenGL application wrapper for LuaJIT.

### Dependencies:

- https://github.com/thenumbernine/lua-ext
- https://github.com/thenumbernine/vec-ffi-lua
- https://github.com/thenumbernine/lua-ffi-bindings for the OpenGL, GLU, SDL bindings
- `glapp.orbit` can detect if the glapp object is a subclass of https://github.com/thenumbernine/lua-imguiapp if available.

I also added view.lua and orbit.lua to add behaviors to GLApp classes
view.lua = View object, applied to the class via View.apply
orbit.lua = function to apply orbit behavior 
