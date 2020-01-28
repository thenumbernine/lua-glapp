OpenGL application wrapper for LuaJIT.

### Dependencies:

- https://github.com/thenumbernine/lua-ext
- https://github.com/thenumbernine/vec-lua in `glapp.orbit` and `glapp.view`
- https://github.com/malkia/ufo and/or https://github.com/thenumbernine/lua-ffi-bindings for the OpenGL, GLU, SDL bindings
- `glapp.orbit` can detect if the glapp object is a subclass of https://github.com/thenumbernine/lua-imguiapp if available.


Uses OpenGL and SDL bindings from Malkia's UFO project at https://github.com/malkia/ufo .
Though feel free to generate your own bindings.  That is always safest.

Using Malkia UFO's bindings:
1) clone https://github.com/malkia/ufo
2) add `/path/to/ufo` to `$LUA_PATH`
3) export `LUAJIT_LIBPATH=/path/to/ufo`
4) inside `/path/to/ufo/ffi/sdl.lua` replace:

`local sdl  = ffi.load( ffi_SDL_lib or ffi_sdl_lib or libs[ ffi.os ][ ffi.arch ]  or "sdl" )`

... with ...

`local sdl  = ffi.load( ffi_SDL_lib or ffi_sdl_lib or `
`	os.getenv('LUAJIT_LIBPATH') .. '/' .. libs[ ffi.os ][ ffi.arch ]  or "sdl" )`

5) add the following line to sdl.lua

`ffi.cdef[[ enum {SDL_INIT_VIDEO = 0x20 }; ]]`


I also added view.lua and orbit.lua to add behaviors to GLApp classes
view.lua = View object, applied to the class via View.apply
orbit.lua = function to apply orbit behavior 
