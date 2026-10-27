# HolyC Graphics Guide

A guide and starter kit for writing graphical programs in HolyC on Linux, macOS and WSL2: software rendering, windows and input, sound, game controllers and OpenGL. It uses the [hcc](https://github.com/Jamesbarford/holyc-lang) compiler with SDL2 and OpenGL. No TempleOS, no VM, and no C or C++ in the examples.

It's thirteen small programs that compile and run, a few hundred lines of reusable HolyC, and a docs site that explains how they fit together. It isn't an engine.

**Docs: https://yatovoid.github.io/holyc-graphics-guide/**

<p align="center">
  <img src="docs/media/sprite.png" width="45%" alt="Sprite demo: a character, a gem and two bats on a checkered floor">
  <img src="docs/media/opengl.png" width="45%" alt="OpenGL demo: a vertex-coloured cube">
</p>
<p align="center">
  <img src="docs/media/draw.png" width="45%" alt="Software-rendered scene: a house, hills and a sun">
  <img src="docs/media/cube.png" width="45%" alt="Software 3D: a shaded cube and pyramid">
</p>

Every image above is output from the example programs in this repo.

## Quick start

```sh
git clone https://github.com/YatoVoid/holyc-graphics-guide.git
cd holyc-graphics-guide

# Debian/Ubuntu dependencies. Other systems: see docs/installation.md
sudo apt install build-essential cmake git libsdl2-dev libsdl2-image-dev libgl-dev

./scripts/build-linux.sh --install-hcc    # builds hcc into ~/.local, then the examples
export PATH="$HOME/.local/bin:$PATH"
./scripts/check.sh                        # build and run every example

cd examples/sprite-demo && hcc -jit sprite.HC
```

macOS: use `./scripts/build-macos.sh`. Windows: run `.\scripts\build-windows.ps1 -InstallHcc`, which does the same thing inside WSL2.

## What's in here

| Path | Contents |
|---|---|
| [`examples/`](examples/) | thirteen programs, from hello world to an OpenGL cube, plus shared HolyC in `common/` |
| [`docs/`](docs/) | the documentation site (MkDocs Material) |
| [`scripts/`](scripts/) | build scripts for Linux, macOS and WSL2, and `check.sh` |

| Example | Shows |
|---|---|
| `hello-world` | HolyC syntax: printing, classes, default arguments |
| `draw-basic` | a software framebuffer: lines, rectangles, circles, triangles, saved as an image |
| `font-text` | a 5x7 bitmap font stored as ASCII art, drawn into the canvas at any scale |
| `image-load` | a PPM reader in HolyC and a PNG through SDL2_image, drawn with transparency |
| `sprite-demo` | a small game: window, frame loop, sprites, keyboard and mouse, collision |
| `tilemap` | a scrolling platformer level stored as a string grid: camera, gravity, tile collision |
| `audio` | square-wave beeps queued with `SDL_QueueAudio`, no callbacks |
| `gamepad` | SDL GameController: sticks, triggers and buttons drawn live, hotplug |
| `templeos-bounce` | TempleOS's `Bounce.HC` demo ported to hcc, with every change explained |
| `simple-3d` | 3D on the CPU: projection, back-face culling, lighting, painter's algorithm |
| `sdl-demo` | SDL's 2D renderer driven directly from HolyC |
| `opengl-demo` | OpenGL 3.3 core: shaders, buffers, matrices, depth testing |
| `gl-texture` | a canvas uploaded as a GL texture every frame and drawn on a quad |

## How the graphics stack works

hcc compiles HolyC to native x86_64 or AArch64 code and links it with the system `cc`. Programs call C libraries directly:

```holyc
#link <SDL2>
extern "c" I32 SDL_Init(U32 flags);
extern "c" U0 *SDL_CreateWindow(U8 *title, I32 x, I32 y, I32 w, I32 h, U32 flags);
```

So a HolyC game is HolyC for the logic, maths and drawing code, SDL2 for the window and input, OpenGL for GPU rendering, and a few lines of GLSL for shaders. [Runtime bindings](https://yatovoid.github.io/holyc-graphics-guide/runtime-bindings/) covers how to write these declarations for any library.

## Status and testing

Everything here is tested against hcc 0.0.15-beta (commit `06ca611`), the newest upstream version as of October 2026. On every push, CI builds that hcc from source and runs [`scripts/check.sh`](scripts/check.sh):

| Platform | What CI runs |
|---|---|
| Linux x86_64 (Ubuntu 24.04) | all thirteen examples, OpenGL included (on Mesa's software renderer) |
| macOS, Apple Silicon and Intel | all thirteen built, all but the two OpenGL examples run |
| Windows (WSL2) | nothing; the build script runs the Linux build inside WSL2, untested by CI |

What a passing run means: every example that draws has a `--ppm` mode, and its frame must match the SHA-256 sum in [`scripts/checksums.txt`](scripts/checksums.txt) byte for byte, on all three CI platforms (the two OpenGL ones on Linux's llvmpipe only). `beep` must play the recorded samples through SDL's disk driver. The window programs must open and keep running for three seconds. That catches crashes and rendering changes, but not everything a person would notice on screen.

## Limitations

- **hcc is a compiler, not an engine.** It provides the language and a small runtime (strings, memory, files). Windows, input, graphics and audio come from C libraries you bind to.
- **TempleOS graphics aren't available.** `GrLine`, `DCFill`, `Sprite3` and the rest are part of the TempleOS kernel, not HolyC.
- **No native Windows.** hcc targets Linux and macOS. Windows users build and run everything inside WSL2.
- **hcc is beta.** Some code compiles but gives wrong results. [Compiler quirks](https://yatovoid.github.io/holyc-graphics-guide/compiler-quirks/) lists every bug found while writing this guide, with workarounds.
- **Some things aren't checked automatically.** CI doesn't run OpenGL on macOS. The OpenGL frames are only compared on Mesa's llvmpipe, because other drivers round a few pixels differently. Live keyboard, mouse and window handling are only checked for starting without a crash.
- **The renderers are for learning.** The software 3D renderer has no depth buffer or clipping. Image loading takes 8-bit PPM in HolyC, or anything SDL2_image reads.

## What's next

The planned examples, docs and CI coverage are done. The remaining work is reporting the hcc bugs in [Compiler quirks](https://yatovoid.github.io/holyc-graphics-guide/compiler-quirks/) upstream and re-testing them on each new hcc release. See the [roadmap](https://yatovoid.github.io/holyc-graphics-guide/roadmap/).

## Credits

HolyC was created by Terry A. Davis for TempleOS. hcc is by James Barford. The guide and examples are MIT-licensed. See [LICENSE](LICENSE).
