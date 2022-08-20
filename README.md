[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=KYWUWS86GSFGL)

OpenGL application wrapper for LuaJIT.

### Dependencies:

- [lua-ext](https://github.com/thenumbernine/lua-ext)
- [vec-ffi-lua](https://github.com/thenumbernine/vec-ffi-lua)
- [lua-ffi-bindigns](https://github.com/thenumbernine/lua-ffi-bindings) for the OpenGL, GLU, SDL bindings
- `glapp.orbit` can detect if the glapp object is a subclass of [lua-imguiapp](https://github.com/thenumbernine/lua-imguiapp) if available.

I also added view.lua and orbit.lua to add behaviors to GLApp classes
- view.lua = View object, applied to the class via View.apply
- orbit.lua = function to apply orbit behavior
