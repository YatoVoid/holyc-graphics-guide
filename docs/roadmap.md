# Roadmap

What exists today is listed under [Example programs](examples.md). Below are the next additions, roughly in order. Contributions are welcome. Open an issue first for anything large.

## Examples

- [x] **Bitmap font text.** Draw strings into the canvas from a font stored in the source, the same way sprites are.
- [x] **Tilemap scroller.** A level stored as a string grid, a camera that follows the player, collision against tiles.
- [x] **Audio.** Square-wave beeps through `SDL_QueueAudio`, with no callbacks.
- [x] **Textured OpenGL.** Upload a canvas as a GL texture and draw it on a quad, which bridges the two halves of this guide.
- [x] **Gamepad input.** `SDL_GameController` declarations and a small test program.
- [x] **Image loading.** A PPM reader in HolyC, and an SDL2_image binding.

## Docs

- [x] A page on [memory arenas](memory-arenas.md) for per-level allocation.
- [x] A worked example of [porting a small TempleOS graphics program](templeos-porting.md).
- [x] Notes on [profiling hcc output](profiling.md) (`perf`, Instruments).

## Testing

- [x] CI builds hcc and runs every example on Linux.
- [ ] macOS CI job.
- [ ] Pixel checksums for the headless examples, so rendering changes are caught as well as crashes.

## Tracking hcc

- [ ] Re-test every entry in [Compiler quirks](compiler-quirks.md) against each new hcc release, and drop the ones that are fixed.
