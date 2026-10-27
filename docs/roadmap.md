# Roadmap

## Where things stand

The examples, docs and CI coverage planned for this guide are done. There are thirteen example programs. CI builds all of them on Linux and on Apple Silicon and Intel Macs, and runs all of them except the two OpenGL ones on macOS. The seven with a headless mode are checked against recorded image checksums. Everything targets hcc 0.0.15-beta (commit `06ca611`), which was still the newest upstream version when the [compiler quirks](compiler-quirks.md) were last re-tested in October 2026.

What's left is mostly about testing more of what the examples do, and about keeping up with hcc as it changes.

## Next

Roughly in order. Each one closes a gap that's already documented.

1. **Check audio output.** CI plays `beep` through SDL's dummy driver, which discards the samples. SDL's disk driver writes them to a file instead. The sound itself comes out the same every run, but the silence after it varies, and sdl2-compat writes stereo even when the program asks for mono, so the check has to normalise the layout and trim the silence before comparing.
2. **Headless modes for the remaining window examples.** `sprite-demo`, `sdl-demo`, `opengl-demo` and `gl-texture` are only checked for opening and staying open. A `--ppm` mode like the other examples' would let CI check what they draw. For the OpenGL two, that also depends on whether Mesa's software renderer gives the same pixels from one version to the next.
3. **Report the compiler quirks upstream.** Each entry has a minimal reproduction already. They belong in [hcc's issue tracker](https://github.com/Jamesbarford/holyc-lang/issues).

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

Contributions are welcome. Open an issue first for anything large.
