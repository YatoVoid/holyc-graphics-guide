# Examples

| Folder | Needs | Run it |
|---|---|---|
| `hello-world/` | nothing | `hcc -jit hello.HC` |
| `draw-basic/` | nothing | `hcc -jit draw.HC` (writes `draw.ppm`) |
| `sprite-demo/` | SDL2 | `hcc -jit sprite.HC` |
| `simple-3d/` | SDL2 | `hcc -jit cube.HC`, or `./cube --ppm out.ppm` after building |
| `sdl-demo/` | SDL2 | `hcc -jit sdl_example.HC` |
| `opengl-demo/` | SDL2, OpenGL 3.3 | `hcc -jit opengl_example.HC` |

Run the commands from inside each folder. To build all of them into `build/bin/`, run `./scripts/build-linux.sh` or `./scripts/build-macos.sh` from the repo root.

`common/` holds the code the examples share:

- `canvas.HC`: a 32-bit framebuffer with pixel, line, rectangle, circle and triangle drawing, and a PPM writer
- `sdl2.HC`: SDL2 declarations and constants, plus `SdlPumpEvents` and `SdlKeyDown`
- `screen.HC`: shows a canvas in a scaled SDL window
- `gl.HC`: OpenGL 3.3 core declarations

Each example includes what it needs with a relative path (`#include "../common/canvas.HC"`). To start your own project, copy one example folder together with `common/`.

Walkthroughs for each example are on the [docs site](https://yatovoid.github.io/holyc-graphics-guide/examples/).
