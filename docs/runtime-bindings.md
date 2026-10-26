# Runtime bindings

HolyC programs reach SDL2, OpenGL or any other C library the same way: declare each function with `extern "c"`, and name the library with `#link`. You don't need C code, wrapper libraries or binding generators.

## `extern "c"`

```holyc
extern "c" I32 SDL_Init(U32 flags);
extern "c" U0 *SDL_CreateWindow(U8 *title, I32 x, I32 y, I32 w, I32 h, U32 flags);
```

This says "a C function with this name and signature exists; call it with the platform's C calling convention." The name must match the C symbol exactly. hcc does no name mangling for these.

## `#link`

```holyc
#link <SDL2>          // like -lSDL2
#link "./libfoo.so"   // a specific file, relative to the working directory
```

For a normal build, `<name>` becomes `-l<name>` on the linker command line, with Homebrew's and `/usr/local`'s lib directories added when they exist. Under `hcc -jit` and the REPL, hcc `dlopen`s `lib<name>.so` or `.dylib` instead. Duplicate `#link` lines are ignored, so every binding file can safely link its own library.

`#link` can't express macOS frameworks. For OpenGL on macOS, pass `-clibs "-framework OpenGL"` on the command line. `scripts/build-macos.sh` does this.

Guard platform-specific links:

```holyc
#ifdef IS_LINUX
#link <GL>
#endif
```

## Mapping C types

| C | HolyC |
|---|---|
| `int`, `Sint32` | `I32` |
| `unsigned`, `Uint32`, `GLenum`, `GLuint`, `GLbitfield` | `U32` |
| `Uint8`, `GLboolean`, `char` | `U8` |
| `long`, `size_t`, `GLsizeiptr`, `GLintptr`, `Sint64` | `I64` |
| `float`, `GLfloat` | `F32` |
| `double` | `F64` |
| `const char *` | `U8 *` |
| `void` | `U0` |
| any pointer to an opaque type (`SDL_Window *`) | `U0 *` |

Width matters. Declaring a C `int` parameter as `I64` usually works on x86_64 by accident, but return values and struct fields must match exactly.

## Structs

Mirror the C layout with a `class`, field for field, in the same order and with the same widths:

```holyc
// C: typedef struct SDL_Rect { int x, y, w, h; } SDL_Rect;
class SdlRect
{
  I32 x, y, w, h;
};
```

For big unions you only need part of, use a byte buffer of the right size and read the part you need. `SDL_Event` is 56 bytes, and its first 4 bytes are always the event type:

```holyc
U8 event[64];
while (SDL_PollEvent(event)) {
  U32 *type = event;
  if (*type == SDL_QUIT)
    running = FALSE;
}
```

## Constants

C headers define constants as macros or enums, and HolyC can't read C headers. Copy the values you need into `#define`s. Take them from the real headers (`SDL_video.h`, `glcorearb.h`), not from memory: a wrong constant compiles fine and fails at runtime, often silently.

## Things that are macros in C

Some "functions" in C headers are macros, so there's no symbol to link against. With SDL2 the common ones are:

| C macro | Call this instead |
|---|---|
| `SDL_LoadBMP(file)` | `SDL_LoadBMP_RW(SDL_RWFromFile(file, "rb"), 1)` |
| `SDL_BUTTON(x)` | `1 << (x - 1)`, or the `SDL_BUTTON_LMASK` constants |
| `SDL_WINDOWPOS_CENTERED` | the value `0x2FFF0000` |

If the linker says `undefined reference to SDL_Something`, check the header for a macro.

## OpenGL without a loader

On Windows, C programs need a loader such as GLAD or GLEW to find OpenGL functions at runtime. On Linux and macOS, `libGL` and `OpenGL.framework` export every core function directly, so `extern "c"` declarations work as-is. That's how `examples/common/gl.HC` works. Function pointers from `SDL_GL_GetProcAddress` are only needed for extensions.

## Callbacks

Passing a HolyC function to C as a callback (for example `SDL_AddEventWatch` or audio callbacks) means taking a function's address. Taking the address of an `extern "c"` function fails when linked as PIE. Taking the address of a HolyC function and handing it to C hasn't been tested by this guide, so prefer polling APIs (`SDL_PollEvent`, `SDL_QueueAudio`) that avoid callbacks.

## Writing bindings for a new library

1. Read the C header. List the functions you actually call.
2. Translate each signature using the table above.
3. Copy the constants you need, with their exact values.
4. Mirror any struct you need to read or write.
5. Write a ten-line test that calls one function and prints the result before building on it.

`examples/common/sdl2.HC` and `examples/common/gl.HC` are both written this way. Use them as templates.
