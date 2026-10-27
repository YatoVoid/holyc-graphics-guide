# Compiler quirks

hcc is beta software, and its README says as much. The bugs below were each hit while writing this guide or [Ossuary](https://github.com/YatoVoid/ossuary), and each was reproduced in a small test program against hcc 0.0.15-beta (commit `06ca611`), as a normal build and under `-jit`, on Linux x86_64 unless the entry says otherwise. They were last re-tested in October 2026, when `06ca611` was still the newest commit upstream. If you're on a newer hcc, test before relying on either the bug or the workaround.

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
Show(speed > 0.01);           // passes 0
```

A float comparison that's **assigned** or **passed as an argument** evaluates to 0. It works as the condition of `if`, `while` or `for`, and as a `return` value.

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

`&&` and `||` test their left operand correctly, but only look at the **low byte** of the right operand. A pointer or `I64` on the right whose low byte is zero counts as false: `0 || 0x100` is false, and so is `5 && 0x200`. `MAlloc` returns 8-byte aligned addresses, so `a && b` on two valid pointers fails about one time in 32. The value of `a && b` isn't 1 either: it's the right operand's low byte, sign-extended, so `5 && 0x2A1` is -95.

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

## `%d` in a print statement is 32-bit

```holyc
I64 big = 1 << 40;
"%d\n", big;                    // prints 0
"%ld\n", big;                   // prints 1099511627776
StrPrint(buf, "%d", big);       // "1099511627776"
```

A bare string used as a print statement formats like C's `printf`: `%d`, `%x` and `%u` take only the low 32 bits of an `I64`, so 2^31 prints as -2147483648 and 2^40 as 0. The value itself is fine. `StrPrint` and `MStrPrint` use TempleOS's formatter instead, where `%d` is the full 64 bits and `%ld` is an error ("Invalid format char").

**Workaround:** in print statements, use `%ld`, `%lx` and `%lu` for anything that can pass 32 bits. In `StrPrint` and `MStrPrint`, keep `%d`.

## Bool && float comparison

```holyc
if (on_ground && speed > 0.0)   // build fails
```

hcc prints `WARNING: Binop has returned null type`, `Binary type is being assigned as NULL` and ``error: The `&&` operator cannot be applied to a character type with a binary op of float type``, then exits with status 1 without writing a binary.

**Workaround:** nest the conditions.

```holyc
if (on_ground) {
  if (speed > 0.0) {
  }
}
```

## Small classes in and out by value under `-jit`

```holyc
class Cell { I32 x, y, z; };
Cell Add(Cell a, Cell b);   // right in a normal build, garbage under -jit
```

Under `hcc -jit`, a function that takes a class by value **and** returns one gives wrong values when the class is made of integers and is 16 bytes or smaller (`3 x I32`, `2 x I64`, `3 x U8` and so on). Normal builds get every case right. Under `-jit`, passing such a class in or returning one is fine on its own, and so are classes of floats and classes bigger than 16 bytes.

**Workaround:** pass an output pointer, which is how all the maths in this guide is written.

```holyc
U0 V3Add(Vec3 *out, Vec3 *a, Vec3 *b);
```

## Call results into a parameter's fields

```holyc
U0 SetCamera(Game *g, I64 x)
{
  g->cam_y = MaxI64(0, x);   // segfault
}
```

Assigning the result of a call straight into a field of a pointer **parameter** crashes when the field isn't the first one in the class and the call takes arguments. hcc keeps the parameter in the register it arrived in, the call's arguments overwrite that register, and the store goes to a garbage address. It happens under `-jit` too.

Which register matters: a pointer that arrived second only breaks when the call has at least two arguments. Copying the parameter into a local (`Game *h = g; h->cam_y = MaxI64(...)`) doesn't help, because the local stays in the same register. These are fine: the first field (offset 0), calls with no arguments, and pointers that didn't come from a parameter, like globals or `&g_game`.

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

Taking `&SomeCFunction` of an `extern "c"` function fails to link as PIE (it works under `-jit`). Call C functions directly instead of storing pointers to them.

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
