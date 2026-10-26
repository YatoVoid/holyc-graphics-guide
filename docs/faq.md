# FAQ

**Is this TempleOS?**
: No. This is HolyC the language, compiled by hcc on Linux or macOS into ordinary native programs. None of TempleOS's kernel, shell or graphics library is involved.

**Can I run my TempleOS programs with this?**
: Pure logic usually ports with small changes. Anything that uses TempleOS APIs (graphics, `DocPrint`, the file system, tasks, `Sprite3`) won't compile, because those APIs live in the TempleOS kernel, not the language. Replace the drawing with the canvas or SDL calls shown here.

**Is there C or C++ in the examples?**
: No. Every example is HolyC, plus two short GLSL shaders inside the OpenGL demo, which the GPU requires. The libraries they call (SDL2, OpenGL drivers, libc) are C, like they are for every language.

**Why SDL2 and not SDL3?**
: SDL2 is packaged everywhere, and its API is stable and well documented. On distributions that have moved to SDL3, `sdl2-compat` provides the SDL2 API. Porting the declarations in `common/sdl2.HC` to SDL3 is mostly renaming.

**Why OpenGL and not Vulkan or Metal?**
: OpenGL 3.3 core runs on Linux, macOS and WSL2, needs no loader on Linux and macOS, and gets a cube on screen in a few hundred lines. Vulkan would need several times the binding work. Apple has deprecated OpenGL but still ships it.

**Is it fast?**
: hcc does basic optimisation (constant folding, some dead-code elimination). It's slower than `gcc -O2` on tight loops, but fast enough for software rendering at retro resolutions, and with OpenGL the GPU does the heavy lifting anyway.

**Can I use audio?**
: Yes, through SDL. The simplest route is `SDL_OpenAudioDevice` with no callback and `SDL_QueueAudio` each frame, which avoids passing a HolyC function to C. This guide doesn't include an audio example yet.

**Can I ship a game made this way?**
: Yes. The output is a normal executable that depends on libc, libm, SDL2 and (for GL) libGL. `libtos` is linked in statically. Ship it the way you'd ship any Linux or macOS binary, and list SDL2 as a dependency or bundle it.

**Do I need to use the JIT?**
: No. `hcc -jit` is a convenience for fast iteration. Normal `hcc file.HC -o name` builds are what you'd ship.

**Where are the HolyC language docs?**
: [holyc-lang.com](https://holyc-lang.com/), maintained by hcc's author. [HolyC basics](basics.md) covers what this guide uses.

**Who made this?**
: The guide and examples are by YatoVoid. hcc is by James Barford. HolyC was created by Terry A. Davis for TempleOS.
