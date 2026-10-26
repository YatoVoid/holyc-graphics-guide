# Troubleshooting

## Building hcc

**`cmake: command not found`**
: Install CMake from your package manager. Without root, `pip install --user cmake` or `uv tool install cmake` also work.

**`make install` fails copying `libtos`**
: The prefix's `lib/` directory doesn't exist. Run `mkdir -p <prefix>/bin <prefix>/lib <prefix>/include` first.

**`hcc: command not found` after installing**
: `<prefix>/bin` isn't on your `PATH`. Add `export PATH="$HOME/.local/bin:$PATH"` to your shell config.

**`tos.HH: No such file or directory` when compiling**
: hcc looks for its runtime under the prefix it was built with. If you moved it, rebuild hcc or pass `--install-dir=<prefix>`.

## Compiling your program

**`sh: cc: command not found`**
: hcc calls `cc` to assemble and link. Install `build-essential` (Debian/Ubuntu), `base-devel` (Arch), or the Xcode command line tools (macOS).

**`Variable or function X has not been defined`**
: Either X is used before it's defined (move it up, or add a prototype), or the file declaring it isn't `#include`d.

**`Type X has not been declared, expected type declaration`**
: You declared two globals on one line. Split them. See [Compiler quirks](compiler-quirks.md#one-global-per-declaration).

**hcc crashes (segmentation fault) while compiling**
: Look for a function-like macro (`#define F(x) ...`). Otherwise, halve the program until you find the line, then [report it](compiler-quirks.md#how-to-report-a-new-one).

**`WARNING: Binop has returned null type`, then the build fails**
: A `Bool` combined with a float comparison using `&&` or `||`. Nest the `if`s.

## Linking

**`cannot find -lSDL2`**
: The SDL2 development package isn't installed. A runtime-only package isn't enough: the linker needs `libSDL2.so`. Install `libsdl2-dev` (Debian/Ubuntu) or `SDL2-devel` (Fedora), or run `brew install sdl2` on macOS. For `-lSDL2_image`, the packages are `libsdl2-image-dev`, `SDL2_image-devel`, `sdl2_image` (Arch) and `sdl2_image` (Homebrew).

**`cannot find -lGL`**
: Install `libgl-dev` (Debian/Ubuntu) or `mesa-libGL-devel` (Fedora).

**`undefined reference to SDL_Something`**
: The name may be a C macro rather than a function (`SDL_LoadBMP` is one). Check the header and call the underlying function. See [Runtime bindings](runtime-bindings.md#things-that-are-macros-in-c).

**macOS: `undefined symbols: _glClear` and friends**
: Add `-clibs "-framework OpenGL"`, or use `scripts/build-macos.sh`.

## Running

**`error while loading shared libraries: libSDL2-2.0.so.0`**
: SDL2's runtime library isn't installed on the machine running the program. Install `libsdl2-2.0-0` (Debian/Ubuntu) or `sdl2-compat` (Arch).

**`SDL_Init failed: No available video device`**
: There's no display. Over SSH, run on the machine itself or use X forwarding. On WSL2, update WSL (`wsl --update`) so WSLg is available. For automated tests, `SDL_VIDEODRIVER=offscreen` runs without a display.

**The window opens and immediately says it's not responding**
: The loop isn't draining events. Call `SdlPumpEvents()` (or `SDL_PollEvent` in a loop) every frame.

**Keyboard does nothing**
: The window needs focus, so click it. `SDL_GetKeyboardState` only updates when events are pumped.

**`SDL_GL_CreateContext failed`**
: The driver can't provide OpenGL 3.3 core. Run `glxinfo -B` (Linux) to see what you have. Virtual machines and old WSL versions often top out lower. Software rendering with Mesa (`LIBGL_ALWAYS_SOFTWARE=1`) supports 3.3 and up.

**OpenGL window is black**
: Check the terminal for a shader compile or link error. The demo prints them. Also check that the vertex attribute layout matches the shader's `location`s and that the matrix is column-major.

## Crashes and wrong results

**Segfault in maths code**
: Look for functions returning a small class by value. Switch them to output pointers. See [Compiler quirks](compiler-quirks.md#returning-small-classes-by-value).

**Values are wrong, often by sign**
: Look for a unary minus on an indexed value (`-v[i] * ...`). See [Compiler quirks](compiler-quirks.md#negating-an-indexed-value).

**A float condition is always true or always false**
: Check that you're comparing to a float literal (`0.0`, not `0`), and that the comparison isn't stored in a variable. See [Compiler quirks](compiler-quirks.md#float-comparisons).

**Works with `-jit` but not with `-o` (or the reverse)**
: The JIT and the normal backend are separate code paths. Narrow the problem down to a small program and report it upstream with both outputs.

## Windows

**`build-windows.ps1`: "WSL is not installed"**
: Run `wsl --install` in an admin PowerShell and reboot.

**`build-windows.ps1` is blocked by execution policy**
: Run `powershell -ExecutionPolicy Bypass -File .\scripts\build-windows.ps1`.

**Can hcc make a `.exe`?**
: No. hcc targets Linux and macOS only. The programs run inside WSL2.
