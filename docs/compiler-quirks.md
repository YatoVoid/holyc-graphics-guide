# Compiler quirks

hcc is beta software, and its README says as much. The bugs below were each hit while writing this guide or [Ossuary](https://github.com/YatoVoid/ossuary), and each was reproduced in a small test program against hcc 0.0.15-beta (commit `06ca611`). Newer versions may have fixed some of them. If you're on a newer hcc, test before relying on either the bug or the workaround.

The dangerous ones compile without any warning and give wrong answers, so they're listed first.

## Negating an indexed value

```holyc
F64 z = -v[0] * s + v[2] * c;   // computes -(v[0] * s + v[2] * c)
```

When the operand of unary minus is an array or pointer index, hcc 0.0.15 negates the entire rest of the expression, not just the operand. This happens with integers too. Plain variables, struct members (`-p->x`), function calls and dereferences (`-*p`) are fine.

**Workaround:** reorder so the negated term isn't first, or use parentheses.

```holyc
F64 z = v[2] * c - v[0] * s;
F64 z = (-v[0]) * s + v[2] * c;
```

## Float comparisons

Two related bugs:

```holyc
if (speed > 0)       // wrong: 0 is an integer literal
if (speed > 0.0)     // right
```

Comparing a float with an **integer literal** truncates the float and compares as unsigned, so negative values look huge. Always write float literals (`0.0`, `1.0`).

```holyc
Bool moving = speed > 0.01;   // always FALSE
return a < b;                 // always 0 when a and b are floats
```

A float comparison used as a **value** (assigned, returned, or passed as an argument) evaluates to 0. Float comparisons only work directly as the condition of `if`, `while` or `for`.

**Workaround:**

```holyc
Bool moving = FALSE;
if (speed > 0.01)
  moving = TRUE;
```

## Pointers and wide integers in `&&` and `||`

```holyc
U8 *a = MAlloc(16), *b = MAlloc(16);
if (a && b)            // FALSE whenever b's address ends in 0x00
  Use(a, b);
return tiles && name;  // same, and the result isn't 0 or 1 either
```

`&&` and `||` test their left operand correctly, but only look at the **low byte** of the right operand. A pointer or `I64` on the right whose low byte is zero counts as false: `0 || 0x100` is false, and so is `5 && 0x200`. Allocations are often 16-byte aligned, so `a && b` on two valid pointers fails roughly one time in sixteen. The value of `a && b` is the right operand's low byte, not 1.

Comparisons, `!x`, `Bool` and other one-byte values are all safe on the right, since they're already 0 or 1.

**Workaround:** compare explicitly, or test with `!`.

```holyc
if (a != NULL && b != NULL)
  Use(a, b);
if (!tiles || !name)
  return FALSE;
return TRUE;
```

## Unsigned 64-bit shifts and conversions

```holyc
U64 u = 0x8000000000000000;
U64 s = u >> 63;   // -1, not 1
F64 f = u;         // -9223372036854775808.0
```

`>>` on a `U64` copies the sign bit like a signed shift, and converting a `U64` to `F64` treats it as signed. Both only show up when the top bit is set, which is exactly what the output of a random number generator or a hash often looks like. `U32` and smaller types are fine.

**Workaround:** mask off the bits the shift may have filled.

```holyc
U64 top53 = (seed >> 11) & 0x1FFFFFFFFFFFFF;
F64 f = top53;     // always positive now
```

## Bool && float comparison

```holyc
if (on_ground && speed > 0.0)   // build fails
```

hcc prints `WARNING: Binop has returned null type` and `Binary type is being assigned as NULL`, then exits with status 1 without writing a binary.

**Workaround:** nest the conditions.

```holyc
if (on_ground) {
  if (speed > 0.0) {
  }
}
```

## Returning small classes by value

```holyc
Vec3 V3Add(Vec3 a, Vec3 b);   // crashes for a 3 x F32 (12-byte) class
```

**Workaround:** pass an output pointer, which is how all the maths in this guide is written.

```holyc
U0 V3Add(Vec3 *out, Vec3 *a, Vec3 *b);
```

## Call results into a parameter's fields

```holyc
U0 SetCamera(Game *g, I64 x)
{
  g->cam_x = MaxI64(0, x);   // segfault
}
```

Assigning the result of a call that takes arguments straight into a field of a pointer **parameter** can crash. hcc keeps the parameter in the register it arrived in, the call's own arguments overwrite that register, and the store goes to a garbage address. It happens under `-jit` too. Calls with no arguments are fine, and so are pointers held in locals (`Player *p = &g->player; p->x = MaxI64(...)`).

**Workaround:** put the result in a local first.

```holyc
x = MaxI64(0, x);
g->cam_x = x;
```

## Initialised globals and Main's arguments

```holyc
U64 g_seed = 1;

I32 Main(I32 argc, U8 **argv)
{
  "%d\n", argc;   // 1 on Apple Silicon, whatever arguments were passed
  return 0;
}
```

On AArch64 (Apple Silicon), a global with an initialiser that hcc can't place in the data section, such as `I64 g_count = 0;` or `U64 g_seed = 1;`, makes `Main`'s `argc` and `argv` wrong. hcc runs those initialisers in a small `main` before calling your `Main`, and it uses the registers holding `argc` and `argv` to do it. `argc` ends up as the last value stored and `argv` as the global's address, so a program that checks for a flag never sees it, and one that reads `argv[1]` can crash. x86_64 isn't affected. Array initialisers and string pointers (`U32 g_palette[16] = {...}`, `U8 *g_name = "..."`) don't trigger it.

**Workaround:** don't initialise scalar globals where they're declared. Globals start at zero, so `= 0` can just be dropped, and any other starting value can be set at the top of `Main` or in a setup function it calls.

## One global per declaration

```holyc
Sprite g_hero, g_bat;   // error: Type `g_bat` has not been declared
I64 g_a, g_b;           // same error
```

This applies to globals only. Locals and class fields can share a line.

**Workaround:** one global per line.

## Function-like macros crash the compiler

```holyc
#define SQ(x) ((x) * (x))   // hcc exits with a segfault
```

**Workaround:** write a function. Plain `#define NAME value` works fine.

## Address of an extern function

Taking `&SomeCFunction` of an `extern "c"` function fails to link as PIE. Call C functions directly instead of storing pointers to them.

## Defined before use

A function used before its definition fails with "Variable or function has not been defined". Either order the file so definitions come first, or add a prototype (`I64 Later(I64 a);`).

## No ternary

`a ? b : c` is a syntax error. Use `if`/`else`.

## How to report a new one

1. Cut it down to the smallest program that shows the problem. Ten lines is typical.
2. Print the expected and actual values side by side.
3. Check whether it happens with `hcc -jit` as well as a normal build.
4. Open an issue at [Jamesbarford/holyc-lang](https://github.com/Jamesbarford/holyc-lang/issues) with the program and `hcc --version`.

Then add it here with a workaround.
