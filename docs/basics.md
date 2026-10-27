# HolyC basics

This is enough HolyC to read and modify the examples. For the full language, see the hcc docs at [holyc-lang.com](https://holyc-lang.com/). The language comes from TempleOS, and hcc implements most of it.

## Types

| HolyC | C equivalent | Notes |
|---|---|---|
| `U0` | `void` | |
| `Bool` | `_Bool` | `TRUE`, `FALSE` |
| `U8` / `I8` | `uint8_t` / `int8_t` | `U8 *` is a string |
| `U16` / `I16`, `U32` / `I32` | | |
| `U64` / `I64` | `uint64_t` / `int64_t` | `I64` is the default integer |
| `F64` | `double` | the default float |
| `F32` | `float` | hcc extension; needed for OpenGL data |

## Functions

```holyc
U0 Move(Player *p, I64 dx, I64 dy = 0)
{
  p->x += dx;
  p->y += dy;
}
```

Default arguments are allowed. A function called with no arguments can drop the parentheses (`Main;`), though the examples always write them.

A function must be declared before it's used. Either define it higher in the file or add a prototype:

```holyc
I64 Later(I64 a);
```

## Classes

`class` is a C struct. There are no methods, but single inheritance works:

```holyc
class Actor
{
  I64 x, y;
};

class Bat : Actor
{
  I64 vx, vy;
};
```

Fields can share a line (`I64 x, y;`). **Globals can't.** Write one global per line. See [Compiler quirks](compiler-quirks.md#one-global-per-declaration).

## Printing

```holyc
"plain text\n";
"%s is %d years old\n", name, age;
U8 *s = MStrPrint("%d,%d", x, y);    // allocates; Free(s) later
StrPrint(buf, "score %d", score);    // into an existing buffer
```

In a print statement, `%d` only formats 32 bits; use `%ld` for larger values. `StrPrint` and `MStrPrint` take `%d` for any size. See [Compiler quirks](compiler-quirks.md#d-in-a-print-statement-is-32-bit).

## Memory

`MAlloc`, `CAlloc` (zeroed), `Free`, `MemSet`, `MemCpy`. There's no garbage collector.

## Maths

Use the C maths library names: `sin`, `cos`, `tan`, `sqrt`, `floor`, `atan2`, `pow`. The TempleOS spellings (`Sqrt`, `Floor`) don't exist in hcc.

## Programs and Main

hcc starts at `Main`. It can return `U0` or `I32` and can take `(I32 argc, U8 **argv)`:

```holyc
I32 Main(I32 argc, U8 **argv)
{
  if (argc > 1)
    "first argument: %s\n", argv[1];
  return 0;
}
```

## Includes and defines

```holyc
#include "../common/canvas.HC"   // relative to this file
#define WIDTH 320
#ifdef IS_LINUX
#endif
#ifjit
  "running under the JIT\n";
#endif
```

hcc defines `IS_LINUX` or `IS_MACOS` for the target, and `__HCC_JIT__` or `__HCC_AOT__` depending on how it's running. `#ifjit` and `#ifaot` are shorthand for checking those.

## What's missing

- No ternary operator (`a ? b : c`). Use `if`.
- No `struct` keyword. Use `class`.
- No function-like macros. `#define SQ(x) ((x) * (x))` crashes hcc 0.0.15 with a segfault instead of giving an error. Write a function.

The first two fail with a normal compile error. The bugs that compile but misbehave are listed in [Compiler quirks](compiler-quirks.md).
