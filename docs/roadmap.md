# Roadmap

## Where things stand

The examples, docs and CI coverage planned for this guide are done. There are thirteen example programs. CI builds all of them on Linux and on Apple Silicon and Intel Macs, and runs all of them except the two OpenGL ones on macOS. Every example that draws is checked against a recorded image checksum (the OpenGL ones on llvmpipe), and the audio example against a checksum of its samples. Everything targets hcc 0.0.15-beta (commit `06ca611`), which was still the newest upstream version when the [compiler quirks](compiler-quirks.md) were last re-tested in October 2026.

What's left is getting the hcc bugs found here reported upstream, and keeping up with hcc as it changes.

## Next

1. **Report the compiler quirks upstream.** Each entry has a minimal reproduction already. They belong in [hcc's issue tracker](https://github.com/Jamesbarford/holyc-lang/issues).

## Ongoing

- Re-test every entry in [Compiler quirks](compiler-quirks.md) against each new hcc release, drop the ones that are fixed, and move the pinned commit in `scripts/common.sh` forward once the examples pass on it.

## Done

### Examples

- [x] **Bitmap font text.** Draw strings into the canvas from a font stored in the source, the same way sprites are.
- [x] **Tilemap scroller.** A level stored as a string grid, a camera that follows the player, collision against tiles.
- [x] **Audio.** Square-wave beeps through `SDL_QueueAudio`, with no callbacks.
- [x] **Textured OpenGL.** Upload a canvas as a GL texture and draw it on a quad, which bridges the two halves of this guide.
- [x] **Gamepad input.** `SDL_GameController` declarations and a small test program.
- [x] **Image loading.** A PPM reader in HolyC, and an SDL2_image binding.

### Docs

- [x] A page on [memory arenas](memory-arenas.md) for per-level allocation.
- [x] A worked example of [porting a small TempleOS graphics program](templeos-porting.md).
- [x] Notes on [profiling hcc output](profiling.md) (`perf`, Instruments).

### Testing

- [x] CI builds hcc and runs every example on Linux, including the OpenGL ones on Mesa's software renderer.
- [x] macOS CI job (Apple Silicon and Intel).
- [x] Pixel checksums for the headless examples, so rendering changes are caught as well as crashes.
- [x] The gamepad example is tested with SDL's virtual controller, including unplugging and replugging.
- [x] The audio example's samples are checked through SDL's disk driver, on SDL2 and on sdl2-compat.
- [x] `--ppm` modes for `sprite-demo`, `sdl-demo`, `opengl-demo` and `gl-texture`. The OpenGL frames match on llvmpipe across Mesa 25.2 and 26.2; other drivers differ by a few pixels, so those checks run on llvmpipe only.

Contributions are welcome. Open an issue first for anything large.
