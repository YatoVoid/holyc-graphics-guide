# Memory arenas

A game level allocates a pile of things that all live exactly as long as the level: the tile grid, enemy and pickup arrays, door links, the level's name. With `MAlloc` and `Free`, every one of them needs its own `Free`, on every path out of the level, including the error paths halfway through loading. Miss one and it leaks once per level change.

An arena replaces that with one block of memory, allocated once. Each allocation takes the next bytes from the block. Ending the level frees everything at once by setting the offset back to zero.

## The arena

```holyc
class Arena
{
  U8 *base;
  I64 size;
  I64 used;
  I64 peak;
};

Bool ArenaInit(Arena *a, I64 size)
{
  MemSet(a, 0, sizeof(Arena));
  U8 *base = MAlloc(size);
  if (!base)
    return FALSE;
  a->base = base;
  a->size = size;
  return TRUE;
}

U0 ArenaFree(Arena *a)
{
  Free(a->base);
  MemSet(a, 0, sizeof(Arena));
}

// Returns `bytes` of zeroed memory, or NULL when the arena is full. Each
// allocation starts on an 8-byte boundary, so it can hold I64, F64 and
// pointers.
U0 *ArenaAlloc(Arena *a, I64 bytes)
{
  I64 start = (a->used + 7) & ~7;
  if (bytes < 0 || start + bytes > a->size) {
    "arena full: %d of %d bytes used, asked for %d more\n", a->used, a->size, bytes;
    return NULL;
  }
  U8 *p = a->base + start;
  MemSet(p, 0, bytes);
  a->used = start + bytes;
  if (a->used > a->peak)
    a->peak = a->used;
  return p;
}

// Everything allocated from the arena is gone after this.
U0 ArenaReset(Arena *a)
{
  a->used = 0;
}
```

hcc's `MAlloc` returns 8-byte aligned memory, and each allocation's offset is rounded up to a multiple of 8, so every allocation is 8-byte aligned. That's enough for any class built from `I64`, `F64` and pointer fields. It isn't 16-byte alignment, which only matters if you hand the memory to C code that needs it.

Zeroing every allocation costs a little, but it means a freshly loaded level never sees the previous level's data in a field you forgot to set. `MAlloc` doesn't zero, and `CAlloc` does. The arena behaves like `CAlloc`.

## Allocating a level

Create the arena once at startup, sized for the biggest level, and reset it on every level change:

```holyc
#define LEVEL_ARENA_BYTES (4 * 1024 * 1024)

class Enemy
{
  I64 x, y;
  I64 hp;
};

class Level
{
  I64 width, height;
  U8 *tiles;
  Enemy *enemies;
  I64 enemy_count;
  U8 *name;
};

U8 *ArenaStrNew(Arena *a, U8 *s)
{
  I64 len = StrLen(s);
  U8 *copy = ArenaAlloc(a, len + 1);
  if (copy)
    MemCpy(copy, s, len + 1);
  return copy;
}

Bool LevelLoad(Level *lv, Arena *arena, U8 *name, I64 width, I64 height, I64 enemies)
{
  ArenaReset(arena);
  MemSet(lv, 0, sizeof(Level));
  lv->width = width;
  lv->height = height;
  lv->enemy_count = enemies;
  lv->tiles = ArenaAlloc(arena, width * height);
  lv->enemies = ArenaAlloc(arena, enemies * sizeof(Enemy));
  lv->name = ArenaStrNew(arena, name);
  if (!lv->tiles || !lv->enemies || !lv->name)
    return FALSE;
  return TRUE;
}
```

The last check tests each pointer with `!` rather than writing `return lv->tiles && lv->enemies && lv->name;`. In hcc 0.0.15 that shorter form is [wrong for pointers](compiler-quirks.md#pointers-and-wide-integers-in-and).

There's no `LevelFree`. A failed load returns `FALSE` and leaves nothing to clean up, because the next `LevelLoad` resets the arena anyway. Nothing about the level touches `Free` until the game exits and calls `ArenaFree` once.

`ArenaReset` doesn't zero the old contents. Each allocation is zeroed when it's handed out, which costs nothing for memory the new level never uses.

## Temporary memory

Loading often needs scratch space that's only used during the load: a decoded file, a list of spawn points before they're sorted, a path search's open list. Taking it from the level arena would waste that space for the whole level.

Save the offset, use the memory, then put the offset back:

```holyc
I64 ArenaMark(Arena *a)
{
  return a->used;
}

// Frees everything allocated since `mark` was taken.
U0 ArenaRestore(Arena *a, I64 mark)
{
  a->used = mark;
}
```

```holyc
I64 mark = ArenaMark(arena);
I64 *spawns = ArenaAlloc(arena, 64 * sizeof(I64));
// ... fill and sort spawns, copy the ones you keep into the level ...
ArenaRestore(arena, mark);
```

Anything allocated after the mark is gone after the restore, including allocations made inside functions you called. Only do this when you know nothing allocated in between needs to survive.

The same idea gives a per-frame arena: a second, small arena reset at the top of every frame, for HUD strings and other memory that only lives until the frame is drawn.

## Sizing

`peak` records the most the arena has ever held. Print it at exit while you're building levels, then set `LEVEL_ARENA_BYTES` comfortably above the largest value you've seen:

```holyc
"level arena: peak %d of %d bytes\n", arena->peak, arena->size;
```

When an allocation doesn't fit, `ArenaAlloc` prints what it was asked for and returns `NULL`. Check the result at load time, as `LevelLoad` does, so a level that's too big fails while loading instead of crashing partway through play.

## What goes wrong

- **Pointers outlive the reset.** After `ArenaReset` or `ArenaRestore`, every pointer into the freed part points at memory the next allocation will reuse. Don't keep pointers to level data in anything that survives a level change, such as the player's save data. Copy the values out.
- **Calling `Free` on arena memory.** Only `base` came from `MAlloc`. Freeing a pointer from the middle of the block corrupts the heap.
- **Runtime functions allocate with `MAlloc`.** `MStrPrint`, `StrNew` and `FileRead` return memory that isn't in the arena and still needs `Free`. Copy what you need into the arena and free the original straight away:

    ```holyc
    U8 *tmp = MStrPrint("Level %d", number);
    lv->name = ArenaStrNew(arena, tmp);
    Free(tmp);
    ```

- **Direct assignment can trip an hcc bug.** If `lv->tiles = ArenaAlloc(...)` crashes, see [Call results into a parameter's fields](compiler-quirks.md#call-results-into-a-parameters-fields). Assign to a local first, then copy the local into the field.

## When not to use one

An arena suits memory that's all freed at the same moment. Objects that come and go independently during a level, like bullets or particles, fit a fixed pool better: an array with an `alive` flag, as in [Sprites and 2D](sprites.md#fixed-pools-instead-of-allocation). The pool's array can itself be allocated from the level arena.
