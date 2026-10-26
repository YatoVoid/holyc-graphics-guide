# Project layout

## This repository

```text
holyc-graphics-guide/
├── README.md
├── mkdocs.yml                 docs site config
├── requirements-docs.txt      pinned MkDocs Material version
├── docs/                      this site
│   └── media/                 screenshots, all taken from the examples
├── examples/
│   ├── common/                shared HolyC: canvas, SDL2 and GL declarations
│   ├── hello-world/
│   ├── draw-basic/
│   ├── sprite-demo/
│   ├── simple-3d/
│   ├── sdl-demo/
│   └── opengl-demo/
├── scripts/
│   ├── build-linux.sh         build examples; --install-hcc builds hcc too
│   ├── build-macos.sh
│   ├── build-windows.ps1      runs build-linux.sh inside WSL2
│   ├── check.sh               build + run every example, report pass/fail
│   └── common.sh              shared by the two shell build scripts
└── .github/workflows/
    ├── pages.yml              build and deploy this site
    └── examples.yml           build hcc and run check.sh on every change
```

## Structuring your own game

hcc compiles one file at a time, and `#include` pastes files in. The usual layout is a single entry file that includes everything else in dependency order:

```text
my-game/
├── build.sh
└── src/
    ├── main.HC          #include "game.HC"; I32 Main() { return GameRun(); }
    ├── game.HC          the include list, in order
    ├── platform/
    │   ├── sdl2.HC      extern "c" declarations, #link <SDL2>
    │   └── gl.HC
    ├── core/
    │   ├── math.HC
    │   └── memory.HC
    ├── render/
    │   ├── canvas.HC    or shader.HC, mesh.HC for OpenGL
    │   └── sprites.HC
    ├── world/
    │   ├── level.HC
    │   ├── player.HC
    │   └── enemy.HC
    └── loop.HC          GameRun: init, frame loop, shutdown
```

```holyc
// game.HC
#include "platform/sdl2.HC"
#include "core/math.HC"
#include "core/memory.HC"
#include "render/canvas.HC"
#include "render/sprites.HC"
#include "world/level.HC"
#include "world/player.HC"
#include "world/enemy.HC"
#include "loop.HC"
```

Some rules of thumb:

- **Order is dependency order.** A file can only use what's included above it, unless you add prototypes.
- **Keep platform code at the bottom of the stack.** Only `platform/` and the renderer should call SDL or GL. Game logic that never touches SDL can be tested headlessly, which matters because you can't unit-test a window in CI.
- **Prefix names by module** (`Canvas*`, `Player*`, `Level*`). There are no namespaces, and everything ends up in one translation unit.
- **Write a headless test entry point.** A second `tests/world_test.HC` that includes your world code (but no renderer) and drives it with fake input catches logic bugs fast. Ossuary's tests work this way.

A minimal `build.sh`:

```sh
#!/usr/bin/env sh
set -e
mkdir -p build
case "$(uname -s)" in
  Darwin) hcc src/main.HC -o build/my-game -clibs "-framework OpenGL" ;;
  *)      hcc src/main.HC -o build/my-game ;;
esac
```

`#include` paths resolve relative to the including file, so you can build from any directory. The exception is the path form of `#link` (`#link "./libfoo.so"`), which resolves against the working directory.

## Assets

If your game loads files at runtime (shaders, levels), resolve paths relative to the executable rather than the working directory, or players launching it from elsewhere will hit "file not found". `SDL_GetBasePath()` returns the executable's directory.
