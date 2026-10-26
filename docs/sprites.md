# Sprites and 2D

![sprite-demo](media/sprite.png)

`examples/sprite-demo/sprite.HC` is a complete small game: a player, collectibles, enemies, collision, a hit flash, a score, and mouse input. It's about 300 lines. This page walks through the techniques it uses.

## Sprites as text

Instead of loading image files, the sprites are written directly in the source as character grids:

```holyc
U8 *g_gem_rows[SPRITE_SIZE] = {
  "........",
  "...cc...",
  "..cwcc..",
  ".cwcccc.",
  ".cccccc.",
  "..cccc..",
  "...cc...",
  "........",
};
```

Each character maps to a color, and `.` is transparent:

```holyc
U32 PaletteColor(U8 ch)
{
  switch (ch) {
    case 'c': return Rgb(60, 220, 200);
    case 'w': return Rgb(230, 255, 255);
    // ...
  }
  return Rgb(255, 0, 255);   // magenta: a character with no color assigned
}
```

Drawing a sprite loops over the grid and skips the dots. That's all a sprite blitter is:

```holyc
for (I64 row = 0; row < SPRITE_SIZE; row++) {
  U8 *line = s->rows[row];
  for (I64 col = 0; col < SPRITE_SIZE; col++) {
    U8 ch = line[col];
    if (ch == '.')
      continue;
    CanvasPixel(c, x + col, y + row, PaletteColor(ch));
  }
}
```

The approach keeps the program to a single file, makes the art easy to diff in git, and means there's no image loader to write. For larger art, see [Loading real images](#loading-real-images).

### Animation

The bat has two frames, wings up and wings down, and switches every 120 ms:

```holyc
Sprite *bat = &g_bat_up;
if ((g->clock_ms / 120) % 2)
  bat = &g_bat_down;
```

More frames work the same way: an array of sprites indexed by `(clock / frame_ms) % frame_count`.

### Flashing

After a hit, the player flashes white for a second. `DrawSprite` takes an optional tint that replaces every opaque pixel's color:

```holyc
U32 tint = 0;
if (g->hurt_ms > 0 && (g->hurt_ms / 80) % 2)
  tint = Rgb(255, 255, 255);
DrawSprite(c, &g_hero, x, y, tint);
```

## Movement with fixed-point numbers

Positions are stored as integers scaled by 256, so `x = 2560` means pixel 10. To draw, divide by 256.

```holyc
#define FP 256
h->x += dx * PLAYER_SPEED * ms;   // PLAYER_SPEED is in 1/256 px per ms
DrawSprite(c, &g_hero, h->x / FP, h->y / FP);
```

This gives smooth sub-pixel movement without floating point. It's a classic technique for 2D games, and with hcc there's a second reason to use it: integer comparisons don't run into the [float comparison bugs](compiler-quirks.md#float-comparisons).

## Collision

Each actor is treated as an 8x8 box, shrunk slightly so near-misses don't count. Two boxes overlap unless one is completely to the left, right, top or bottom of the other:

```holyc
Bool Overlaps(Actor *a, Actor *b)
{
  I64 ax = a->x / FP, ay = a->y / FP;
  I64 bx = b->x / FP, by = b->y / FP;
  if (ax + SPRITE_SIZE - 2 <= bx + 1 || bx + SPRITE_SIZE - 2 <= ax + 1)
    return FALSE;
  if (ay + SPRITE_SIZE - 2 <= by + 1 || by + SPRITE_SIZE - 2 <= ay + 1)
    return FALSE;
  return TRUE;
}
```

## Fixed pools instead of allocation

Bats live in a fixed array with an `alive` flag:

```holyc
Actor bats[MAX_BATS];
```

Spawning finds the first dead slot, and nothing is ever freed. For games with a known upper bound on objects, this avoids per-frame `MAlloc`/`Free` and the leaks and crashes that come with them.

## Random numbers

hcc's runtime library has no random-number functions, so the demo uses a three-line linear congruential generator seeded from `SDL_GetTicks()`. (You could declare libc's `rand` with `extern "c"` instead.) Owning the generator also makes runs reproducible: seed it with a constant and the same bats appear in the same places, which helps when debugging.

## Loading real images

hcc has no image decoder. Your options:

- **PPM/PGM.** Trivial to parse: a text header, then raw bytes. Convert your PNGs with `magick sprite.png sprite.ppm`, then read them with `FileRead`.
- **`SDL_LoadBMP`.** SDL can load BMP files itself. It's a macro in C, so declare the real function, `SDL_LoadBMP_RW(SDL_RWFromFile(path, "rb"), 1)`. Then convert the surface or blit it.
- **SDL2_image.** Declare `IMG_Load` from `libSDL2_image` with `extern "c"` and `#link <SDL2_image>` for PNG and JPEG.
- **Generate the art in code.** Ossuary, a HolyC game this guide grew out of, generates all its textures procedurally.
