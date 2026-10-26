# Quick start

This assumes `hcc --version` works. If it doesn't, see [Installation](installation.md).

## Hello world

Make a file called `hello.HC`:

```holyc
U0 Main()
{
  "Hello from HolyC!\n";
}
```

A string literal on its own line is a print statement. That's standard HolyC, not a hcc extension.

There are two ways to run it:

```sh
hcc hello.HC -o hello && ./hello   # compile ahead of time to a native binary
hcc -jit hello.HC                  # compile in memory and run immediately
```

Use `-jit` while you iterate and `-o` when you want a binary to keep or share. Both start at `Main`.

## The REPL

```sh
hcc -repl
```

Definitions accumulate as you type, and statements run immediately. Typing these two lines prints `144`:

```holyc
I64 Square(I64 x) { return x * x; }
"%d\n", Square(12);
```

Put helpers you always want in `~/.hcc_rc.HC`. It's loaded when the REPL starts.

## Draw something without a window

The `draw-basic` example writes an image file using nothing but HolyC:

```sh
cd examples/draw-basic
hcc -jit draw.HC
```

It saves `draw.ppm` in the current directory. Most image viewers open PPM files. To convert one to PNG: `magick draw.ppm draw.png` (ImageMagick) or `ffmpeg -i draw.ppm draw.png`.

![draw-basic output](media/draw.png)

## Open a window

```sh
cd examples/sprite-demo
hcc -jit sprite.HC
```

Arrow keys or ++w++ ++a++ ++s++ ++d++ move the character. Collect gems, avoid bats, click to release more bats, and press ++escape++ to quit.

The sprite demo needs SDL2. The `#link <SDL2>` line in `examples/common/sdl2.HC` tells hcc to link it, so you don't pass any flags. Under `-jit`, hcc loads the library with `dlopen` instead.

## Build everything

From the repo root:

```sh
./scripts/build-linux.sh       # macOS: ./scripts/build-macos.sh
ls build/bin
```

Run window programs from their own example folder, or from anywhere, since none of them load files at runtime:

```sh
./build/bin/cube
./build/bin/opengl_example
```

## Your own project

Copy an example folder and `examples/common/` next to each other, and keep the relative `#include` paths. See [Project layout](project-structure.md) for how to grow it from there.
