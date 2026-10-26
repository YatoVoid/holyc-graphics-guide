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
