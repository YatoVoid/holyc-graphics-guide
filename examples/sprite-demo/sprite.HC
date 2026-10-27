// Sprites drawn from ASCII art into a software canvas, shown through SDL.
//
//   ./sprite              open a window; arrow keys or WASD move the
//                         player, click to release a bat, Esc quits
//   ./sprite --ppm a.ppm  play three scripted seconds with no window,
//                         then save that frame
//
// Collect gems, avoid bats.

#include "../common/canvas.HC"
#include "../common/sdl2.HC"
#include "../common/screen.HC"

#define WIDTH  240
#define HEIGHT 160
#define SCALE  4

// Positions are fixed point with 8 fractional bits: 256 units = 1 pixel.
// Integer math keeps movement smooth without floating point.
#define FP          256
#define PLAYER_SPEED 24
#define MAX_BATS    24

#define SPRITE_SIZE 8

class Sprite
{
  U8 **rows;
};

U8 *g_hero_rows[SPRITE_SIZE] = {
  "..yyyy..",
  ".yyyyyy.",
  ".ysyysy.",
  ".yyyyyy.",
  "..bbbb..",
  ".bbbbbb.",
  "..b..b..",
  ".kk..kk.",
};

U8 *g_bat_up_rows[SPRITE_SIZE] = {
  "p......p",
  "pp....pp",
  "ppp..ppp",
  ".pprrpp.",
  "..pppp..",
  "...pp...",
  "........",
  "........",
};

U8 *g_bat_down_rows[SPRITE_SIZE] = {
  "........",
  "........",
  "...pp...",
  "..prrp..",
  ".pppppp.",
  "pp.pp.pp",
  "p......p",
  "........",
};

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

U32 PaletteColor(U8 ch)
{
  switch (ch) {
    case 'y': return Rgb(240, 200, 150);
    case 's': return Rgb(30, 30, 40);
    case 'b': return Rgb(60, 110, 220);
    case 'k': return Rgb(90, 60, 40);
    case 'p': return Rgb(120, 60, 150);
    case 'r': return Rgb(255, 60, 60);
    case 'c': return Rgb(60, 220, 200);
    case 'w': return Rgb(230, 255, 255);
  }
  return Rgb(255, 0, 255);
}

// '.' is transparent. `tint` replaces every opaque pixel when non-zero,
// which is how the player flashes after a hit.
U0 DrawSprite(Canvas *c, Sprite *s, I64 x, I64 y, U32 tint = 0)
{
  for (I64 row = 0; row < SPRITE_SIZE; row++) {
    U8 *line = s->rows[row];
    for (I64 col = 0; col < SPRITE_SIZE; col++) {
      U8 ch = line[col];
      if (ch == '.')
        continue;
      U32 color = PaletteColor(ch);
      if (tint)
        color = tint;
      CanvasPixel(c, x + col, y + row, color);
    }
  }
}

class Actor
{
  Bool alive;
  I64 x, y;
  I64 vx, vy;
};

class Input
{
  I64 dx, dy;
  I64 mouse_x, mouse_y;
  Bool clicking;
};

class Game
{
  Actor hero;
  Actor gem;
  Actor bats[MAX_BATS];
  I64 score;
  I64 best;
  I64 hurt_ms;
  I64 clock_ms;
  U64 seed;
  Bool was_clicking;
};

Sprite g_hero;
Sprite g_bat_up;
Sprite g_bat_down;
Sprite g_gem;
Game g_game;

I64 Random(Game *g, I64 n)
{
  g->seed = g->seed * 6364136223846793005 + 1442695040888963407;
  I64 v = (g->seed >> 33) & 0x7FFFFFFF;
  return v % n;
}

U0 PlaceGem(Game *g)
{
  g->gem.alive = TRUE;
  g->gem.x = (8 + Random(g, WIDTH - 16 - SPRITE_SIZE)) * FP;
  g->gem.y = (8 + Random(g, HEIGHT - 16 - SPRITE_SIZE)) * FP;
}

U0 SpawnBat(Game *g, I64 px, I64 py)
{
  for (I64 i = 0; i < MAX_BATS; i++) {
    Actor *b = &g->bats[i];
    if (b->alive)
      continue;
    b->alive = TRUE;
    b->x = px * FP;
    b->y = py * FP;
    b->vx = 8 + Random(g, 10);
    b->vy = 8 + Random(g, 10);
    if (Random(g, 2))
      b->vx = -b->vx;
    if (Random(g, 2))
      b->vy = -b->vy;
    return;
  }
}

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

U0 MoveHero(Game *g, Input *in, I64 ms)
{
  Actor *h = &g->hero;
  h->x += in->dx * PLAYER_SPEED * ms;
  h->y += in->dy * PLAYER_SPEED * ms;
  h->x = MaxI64(0, MinI64(h->x, (WIDTH - SPRITE_SIZE) * FP));
  h->y = MaxI64(0, MinI64(h->y, (HEIGHT - SPRITE_SIZE) * FP));
}

U0 MoveBat(Actor *b, I64 ms)
{
  b->x += b->vx * ms;
  b->y += b->vy * ms;
  I64 max_x = (WIDTH - SPRITE_SIZE) * FP, max_y = (HEIGHT - SPRITE_SIZE) * FP;
  if (b->x < 0 || b->x > max_x) {
    b->vx = -b->vx;
    b->x = MaxI64(0, MinI64(b->x, max_x));
  }
  if (b->y < 0 || b->y > max_y) {
    b->vy = -b->vy;
    b->y = MaxI64(0, MinI64(b->y, max_y));
  }
}

U0 Update(Game *g, Input *in, I64 ms)
{
  g->clock_ms += ms;
  MoveHero(g, in, ms);

  if (in->clicking && !g->was_clicking)
    SpawnBat(g, in->mouse_x - SPRITE_SIZE / 2, in->mouse_y - SPRITE_SIZE / 2);
  g->was_clicking = in->clicking;

  if (Overlaps(&g->hero, &g->gem)) {
    g->score++;
    g->best = MaxI64(g->best, g->score);
    PlaceGem(g);
    if (g->score % 3 == 0)
      SpawnBat(g, Random(g, WIDTH - SPRITE_SIZE), 0);
  }

  if (g->hurt_ms > 0)
    g->hurt_ms -= ms;

  for (I64 i = 0; i < MAX_BATS; i++) {
    Actor *b = &g->bats[i];
    if (!b->alive)
      continue;
    MoveBat(b, ms);
    if (g->hurt_ms <= 0 && Overlaps(&g->hero, b)) {
      g->score = 0;
      g->hurt_ms = 1000;
    }
  }
}

U0 Draw(Game *g, Input *in, Canvas *c)
{
  CanvasClear(c, Rgb(24, 22, 34));
  for (I64 y = 0; y < HEIGHT; y += 16)
    for (I64 x = (y / 16 % 2) * 16; x < WIDTH; x += 32)
      CanvasFillRect(c, x, y, 16, 16, Rgb(30, 28, 42));

  I64 bob = (g->clock_ms / 200) % 2;
  DrawSprite(c, &g_gem, g->gem.x / FP, g->gem.y / FP - bob);

  Sprite *bat = &g_bat_up;
  if ((g->clock_ms / 120) % 2)
    bat = &g_bat_down;
  for (I64 i = 0; i < MAX_BATS; i++)
    if (g->bats[i].alive)
      DrawSprite(c, bat, g->bats[i].x / FP, g->bats[i].y / FP);

  U32 tint = 0;
  if (g->hurt_ms > 0 && (g->hurt_ms / 80) % 2)
    tint = Rgb(255, 255, 255);
  DrawSprite(c, &g_hero, g->hero.x / FP, g->hero.y / FP, tint);

  for (I64 i = 0; i < g->score; i++)
    CanvasFillRect(c, 4 + i * 5, 4, 3, 3, Rgb(60, 220, 200));

  I64 mx = in->mouse_x, my = in->mouse_y;
  CanvasLine(c, mx - 3, my, mx + 3, my, Rgb(255, 255, 255));
  CanvasLine(c, mx, my - 3, mx, my + 3, Rgb(255, 255, 255));
}

U0 ReadInput(Screen *s, Input *in)
{
  I64 dx = 0, dy = 0;
  if (SdlKeyDown(SC_LEFT) || SdlKeyDown(SC_A))
    dx--;
  if (SdlKeyDown(SC_RIGHT) || SdlKeyDown(SC_D))
    dx++;
  if (SdlKeyDown(SC_UP) || SdlKeyDown(SC_W))
    dy--;
  if (SdlKeyDown(SC_DOWN) || SdlKeyDown(SC_S))
    dy++;
  I64 mx, my;
  Bool clicking = ScreenMouse(s, &mx, &my);
  in->dx = dx;
  in->dy = dy;
  in->mouse_x = mx;
  in->mouse_y = my;
  in->clicking = clicking;
}

U0 NewGame(Game *g, U64 seed)
{
  g->seed = seed;
  g->hero.x = (WIDTH / 2) * FP;
  g->hero.y = (HEIGHT / 2) * FP;
  PlaceGem(g);
  SpawnBat(g, 20, 20);
  SpawnBat(g, WIDTH - 30, HEIGHT - 30);
}

// A fixed seed and a fixed path: up and left to the first gem, a click
// that releases a third bat, then down and right. The same frame comes
// out every time.
I32 RenderToFile(Game *g, U8 *path)
{
  NewGame(g, 1);
  Input in;
  MemSet(&in, 0, sizeof(Input));
  in.mouse_x = 60;
  in.mouse_y = 100;
  for (I64 t = 0; t < 3000; t += 16) {
    in.dx = -1;
    in.dy = -1;
    if (t >= 280)
      in.dx = 0;
    if (t >= 800) {
      in.dx = 1;
      in.dy = 1;
    }
    in.clicking = t >= 500 && t < 600;
    Update(g, &in, 16);
  }

  Canvas c;
  if (!CanvasInit(&c, WIDTH, HEIGHT)) {
    "out of memory\n";
    return 1;
  }
  Draw(g, &in, &c);
  Bool ok = CanvasSavePpm(&c, path);
  CanvasFree(&c);
  if (!ok) {
    "could not write %s\n", path;
    return 1;
  }
  "wrote %s, score %d, best %d\n", path, g->score, g->best;
  return 0;
}

I32 Main(I32 argc, U8 **argv)
{
  g_hero.rows = g_hero_rows;
  g_bat_up.rows = g_bat_up_rows;
  g_bat_down.rows = g_bat_down_rows;
  g_gem.rows = g_gem_rows;

  Game *g = &g_game;
  if (argc > 2 && !StrCmp(argv[1], "--ppm"))
    return RenderToFile(g, argv[2]);

  Screen screen;
  if (!ScreenOpen(&screen, "HolyC sprites", WIDTH, HEIGHT, SCALE))
    return 1;
  NewGame(g, SDL_GetTicks() + 1);

  Input in;
  I64 shown_score = -1;
  while (SdlPumpEvents() && !SdlKeyDown(SC_ESCAPE)) {
    ReadInput(&screen, &in);
    Update(g, &in, ScreenFrameMs(&screen));
    Draw(g, &in, &screen.canvas);
    ScreenPresent(&screen);

    if (g->score != shown_score) {
      U8 title[64];
      StrPrint(title, "HolyC sprites  -  gems %d  best %d", g->score, g->best);
      SDL_SetWindowTitle(screen.window, title);
      shown_score = g->score;
    }
  }

  ScreenClose(&screen);
  return 0;
}
