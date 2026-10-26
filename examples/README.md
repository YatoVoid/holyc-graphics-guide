# Examples

| Folder | Needs | Run it |
|---|---|---|
| `hello-world/` | nothing | `hcc -jit hello.HC` |
| `draw-basic/` | nothing | `hcc -jit draw.HC` (writes `draw.ppm`) |
| `font-text/` | nothing | `hcc -jit text.HC` (writes `text.ppm`) |
| `image-load/` | SDL2, SDL2_image | `hcc -jit load.HC` (writes `load.ppm`) |
| `sprite-demo/` | SDL2 | `hcc -jit sprite.HC` |
| `tilemap/` | SDL2 | `hcc -jit tilemap.HC`, or `./tilemap --ppm out.ppm` after building |
| `audio/` | SDL2 | `hcc -jit beep.HC` |
| `gamepad/` | SDL2 | `hcc -jit pad.HC` |
| `templeos-bounce/` | SDL2 | `hcc -jit bounce.HC`, or `./bounce --ppm out.ppm` after building |
| `simple-3d/` | SDL2 | `hcc -jit cube.HC`, or `./cube --ppm out.ppm` after building |
| `sdl-demo/` | SDL2 | `hcc -jit sdl_example.HC` |
| `opengl-demo/` | SDL2, OpenGL 3.3 | `hcc -jit opengl_example.HC` |
| `gl-texture/` | SDL2, OpenGL 3.3 | `hcc -jit texture.HC` |

Run the commands from inside each folder. To build all of them into `build/bin/`, run `./scripts/build-linux.sh` or `./scripts/build-macos.sh` from the repo root.

`common/` holds the code the examples share:

- `canvas.HC`: a 32-bit framebuffer with pixel, line, rectangle, circle and triangle drawing, blitting, and a PPM reader and writer
- `font.HC`: a 5x7 bitmap font, `FontDrawText` and `FontTextWidth`
- `sdl2.HC`: SDL2 declarations and constants (video, audio, game controllers), plus `SdlPumpEvents` and `SdlKeyDown`
- `audio.HC`: square-wave beeps queued with `SDL_QueueAudio`
- `sdl2_image.HC`: `IMG_Load` and `CanvasLoadImage` for PNG, JPEG and other formats
- `screen.HC`: shows a canvas in a scaled SDL window
- `gl.HC`: OpenGL 3.3 core declarations

Each example includes what it needs with a relative path (`#include "../common/canvas.HC"`). To start your own project, copy one example folder together with `common/`.

Walkthroughs for each example are on the [docs site](https://yatovoid.github.io/holyc-graphics-guide/examples/).
