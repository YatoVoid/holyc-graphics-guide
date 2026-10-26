# Example programs

All six build with `./scripts/build-linux.sh` (or `build-macos.sh`) into `build/bin/`, and all are checked by `./scripts/check.sh`. You can also run any of them straight from its folder with `hcc -jit <file>.HC`.

| Example | Needs | Shows |
|---|---|---|
| [hello-world](#hello-world) | nothing | printing, classes, default arguments, loops |
| [draw-basic](#draw-basic) | nothing | software framebuffer, lines, rectangles, circles, triangles, saving an image |
| [sprite-demo](#sprite-demo) | SDL2 | window, frame loop, sprites, animation, keyboard and mouse, collision |
| [simple-3d](#simple-3d) | SDL2 | 3D maths and a software rasterizer: projection, culling, lighting |
| [sdl-demo](#sdl-demo) | SDL2 | SDL's own 2D renderer without the canvas, input, timing |
| [opengl-demo](#opengl-demo) | SDL2, OpenGL 3.3 | GL context, shaders, vertex buffers, matrices, depth testing |

The shared code they include lives in `examples/common/`:

| File | Contents |
|---|---|
| `canvas.HC` | framebuffer and drawing functions, PPM writer, integer min/max/abs |
| `sdl2.HC` | SDL2 declarations, constants, scancodes, `SdlPumpEvents`, `SdlKeyDown` |
| `screen.HC` | shows a canvas in a scaled window; frame timing; mouse in canvas pixels |
| `gl.HC` | OpenGL 3.3 core declarations |

## hello-world

```sh
cd examples/hello-world && hcc -jit hello.HC
```

```holyc
--8<-- "examples/hello-world/hello.HC"
```

## draw-basic

```sh
cd examples/draw-basic && hcc -jit draw.HC     # writes draw.ppm
```

![draw-basic](media/draw.png)

Draws a sky gradient, hills, a sun and a house into a 320x200 canvas, then saves it as a PPM. Each shape is a single canvas call. It's the best starting point for experimenting, because there's no window to manage.

??? example "draw.HC"
    ```holyc
    --8<-- "examples/draw-basic/draw.HC"
    ```

## sprite-demo

```sh
cd examples/sprite-demo && hcc -jit sprite.HC
```

![sprite-demo](media/sprite.png)

| Input | Action |
|---|---|
| ++arrow-keys++ or ++w++ ++a++ ++s++ ++d++ | move |
| left click | release a bat at the cursor |
| ++escape++ | quit |

Collect gems. Every third gem releases another bat, and touching a bat resets your score. The window title shows your score and best. [Sprites and 2D](sprites.md) walks through the code.

## simple-3d

```sh
cd examples/simple-3d && hcc -jit cube.HC
hcc cube.HC -o cube && ./cube --ppm frame.ppm     # one frame, no window
```

![simple-3d](media/cube.png)

A cube and a pyramid rendered on the CPU. ++space++ toggles wireframe. **This is a concept demo for learning the 3D pipeline, not a technique to build a game on.** [3D overview](3d-overview.md) explains each stage and what to use instead.

## sdl-demo

```sh
cd examples/sdl-demo && hcc -jit sdl_example.HC
```

![sdl-demo](media/sdl.png)

Uses `SDL_RenderFillRect` and `SDL_RenderDrawLine` directly instead of a canvas. ++arrow-keys++ move the white box, holding the left mouse button drags the orange one, and the green one bounces. This is the quickest route to a working 2D game when you don't need per-pixel control.

## opengl-demo

```sh
cd examples/opengl-demo && hcc -jit opengl_example.HC
# macOS, ahead-of-time:
hcc opengl_example.HC -o opengl_example -clibs "-framework OpenGL"
```

![opengl-demo](media/opengl.png)

A spinning, vertex-coloured cube. It prints the OpenGL version and renderer it got, which is the first thing to check when something doesn't draw.

??? example "opengl_example.HC"
    ```holyc
    --8<-- "examples/opengl-demo/opengl_example.HC"
    ```
