// A side-scrolling level stored as a string grid. The camera follows the
// player and stops at the level edges; the player collides with the tiles.
//
//   ./tilemap              open a window; arrows or A/D run, Space/W/Up
//                          jumps, Esc quits
//   ./tilemap --ppm a.ppm  play two seconds of holding right and jump with
//                          no window, then save that frame

#include "../common/canvas.HC"
#include "../common/font.HC"
#include "../common/sdl2.HC"
#include "../common/screen.HC"

#define WIDTH  240
#define HEIGHT 160
#define SCALE  4

#define TILE  8
#define MAP_W 100
#define MAP_H 24

// Positions are fixed point, 256 units to a pixel. Speeds are in pixels
// per second times 256, so a step moves by speed * ms / 1000.
#define FP           256
#define RUN_SPEED    (90 * FP)
#define JUMP_SPEED   (250 * FP)
#define GRAVITY      (800 * FP)
#define MAX_FALL     (300 * FP)
#define MAX_STEP_MS  10

#define PLAYER_W 6
#define PLAYER_H 8

// '#' ground, '=' platform, '*' gem, '@' where the player starts.
U8 *g_level_rows[MAP_H] = {
  "....................................................................................................",
  "....................................................................................................",
  "....................................................................................................",
  "....................................................................................................",
  "....................................................................................................",
  "....................................................................................................",
  "....................................................................................................",
  "...................................................*................................................",
  ".................................................=====..............................................",
  "....................................................................................................",
  "...........................................*........................................................",
  ".........................................=====......................................................",
  "....................................................................................................",
  "...................................*..............................*.................................",
  ".................................=====...........................####.......................*.......",
  ".................................................................####.....................####......",
  "........................*........................................####....*................####......",
  "...............*......=====..............................*..===..####...====..............####......",
  "..............####...........**..................................####............*....########......",
  "..............####...............................................####.................########......",
  "...@..........####...............................................####.................########......",
  "############################....#######################.....####################...#################",
  "############################....#######################.....####################...#################",
  "############################....#######################.....####################...#################",
};

U8 *g_hero_rows[TILE] = {
  "..yyyy..",
  ".yyyyyy.",
  ".ysyysy.",
  ".yyyyyy.",
  "..bbbb..",
  ".bbbbbb.",
  "..b..b..",
  ".kk..kk.",
};

class Input
{
  I64 dx;
  Bool jump;
};

class Player
{
  I64 x, y;
  I64 vx, vy;
  Bool on_ground;
};

class Game
{
  U8 map[MAP_W * MAP_H];
  Player player;
  I64 start_x, start_y;
  I64 gems, gems_total;
  I64 cam_x, cam_y;
};

Game g_game;

// The rows are string literals, which can't be written to, so the level
// is copied into the game where collected gems can be erased.
U0 LoadLevel(Game *g)
{
  g->gems = 0;
  g->gems_total = 0;
  for (I64 ty = 0; ty < MAP_H; ty++) {
    for (I64 tx = 0; tx < MAP_W; tx++) {
      U8 ch = g_level_rows[ty][tx];
      if (ch == '@') {
        g->start_x = tx * TILE * FP;
        g->start_y = ty * TILE * FP;
        ch = '.';
      }
      if (ch == '*')
        g->gems_total++;
      g->map[ty * MAP_W + tx] = ch;
    }
  }
}

U8 TileAt(Game *g, I64 tx, I64 ty)
{
  if (tx < 0 || tx >= MAP_W)
    return '#';
  if (ty < 0 || ty >= MAP_H)
    return '.';
  return g->map[ty * MAP_W + tx];
}

// Coordinates are pixels. The left and right edges of the level are
// walls; above and below it is open air.
Bool SolidAt(Game *g, I64 px, I64 py)
{
  if (px < 0)
    return TRUE;
  if (py < 0)
    return FALSE;
  U8 ch = TileAt(g, px / TILE, py / TILE);
  return ch == '#' || ch == '=';
}

// The box is no bigger than a tile, so testing its corners is enough.
Bool BoxSolid(Game *g, I64 x, I64 y, I64 w, I64 h)
{
  return SolidAt(g, x, y) || SolidAt(g, x + w - 1, y) ||
         SolidAt(g, x, y + h - 1) || SolidAt(g, x + w - 1, y + h - 1);
}

U0 Respawn(Game *g)
{
  Player *p = &g->player;
  p->x = g->start_x;
  p->y = g->start_y;
  p->vx = 0;
  p->vy = 0;
}

// Move on one axis at a time. If the move ends inside a tile, push the
// player back to the tile's edge on that axis and stop there.
U0 MoveX(Game *g, Player *p, I64 ms)
{
  p->x += p->vx * ms / 1000;
  // Division rounds toward zero, so x = -100 would still be pixel 0 and
  // miss the wall left of the map. Stop at the edge here instead.
  if (p->x < 0) {
    p->x = 0;
    p->vx = 0;
  }
  I64 px = p->x / FP, py = p->y / FP;
  if (!BoxSolid(g, px, py, PLAYER_W, PLAYER_H))
    return;
  if (p->vx > 0)
    px = (px + PLAYER_W - 1) / TILE * TILE - PLAYER_W;
  else
    px = (px / TILE + 1) * TILE;
  p->x = px * FP;
  p->vx = 0;
}

U0 MoveY(Game *g, Player *p, I64 ms)
{
  p->y += p->vy * ms / 1000;
  I64 px = p->x / FP, py = p->y / FP;
  if (!BoxSolid(g, px, py, PLAYER_W, PLAYER_H))
    return;
  if (p->vy > 0)
    py = (py + PLAYER_H - 1) / TILE * TILE - PLAYER_H;
  else
    py = (py / TILE + 1) * TILE;
  p->y = py * FP;
  p->vy = 0;
}

U0 CollectGems(Game *g, Player *p)
{
  I64 px = p->x / FP, py = p->y / FP;
  for (I64 cy = py; cy < py + PLAYER_H; cy += PLAYER_H - 1) {
    for (I64 cx = px; cx < px + PLAYER_W; cx += PLAYER_W - 1) {
      if (cx < 0 || cy < 0 || TileAt(g, cx / TILE, cy / TILE) != '*')
        continue;
      g->map[(cy / TILE) * MAP_W + cx / TILE] = '.';
      g->gems++;
    }
  }
}

// Long frames are split into short steps. At MAX_FALL a 10 ms step moves
// 3 pixels, well under a tile, so the player can't pass through a floor.
U0 Step(Game *g, Input *in, I64 ms)
{
  Player *p = &g->player;
  p->vx = in->dx * RUN_SPEED;
  if (in->jump && p->on_ground)
    p->vy = -JUMP_SPEED;
  p->vy = MinI64(p->vy + GRAVITY * ms / 1000, MAX_FALL);

  MoveX(g, p, ms);
  MoveY(g, p, ms);
  p->on_ground = BoxSolid(g, p->x / FP, p->y / FP + 1, PLAYER_W, PLAYER_H);
  CollectGems(g, p);

  if (p->y / FP > MAP_H * TILE)
    Respawn(g);
}

U0 UpdateCamera(Game *g)
{
  Player *p = &g->player;
  I64 x = p->x / FP + PLAYER_W / 2 - WIDTH / 2;
  I64 y = p->y / FP + PLAYER_H / 2 - HEIGHT / 2;
  // Through locals: see "Call results into a parameter's fields" in
  // docs/compiler-quirks.md.
  x = MaxI64(0, MinI64(x, MAP_W * TILE - WIDTH));
  y = MaxI64(0, MinI64(y, MAP_H * TILE - HEIGHT));
  g->cam_x = x;
  g->cam_y = y;
}

U0 Update(Game *g, Input *in, I64 ms)
{
  while (ms > 0) {
    I64 step = MinI64(ms, MAX_STEP_MS);
    Step(g, in, step);
    ms -= step;
  }
  UpdateCamera(g);
}

U32 HeroColor(U8 ch)
{
  switch (ch) {
    case 'y': return Rgb(240, 200, 150);
    case 's': return Rgb(30, 30, 40);
    case 'b': return Rgb(60, 110, 220);
    case 'k': return Rgb(90, 60, 40);
  }
  return Rgb(255, 0, 255);
}

U0 DrawTile(Game *g, Canvas *c, I64 tx, I64 ty, I64 x, I64 y)
{
  switch (TileAt(g, tx, ty)) {
    case '#':
      CanvasFillRect(c, x, y, TILE, TILE, Rgb(92, 64, 48));
      CanvasPixel(c, x + 2 + (tx * 3 + ty) % 4, y + 3 + (tx + ty) % 3, Rgb(70, 48, 36));
      if (!SolidAt(g, tx * TILE, ty * TILE - 1))
        CanvasFillRect(c, x, y, TILE, 2, Rgb(80, 180, 80));
      break;
    case '=':
      CanvasFillRect(c, x, y, TILE, 4, Rgb(170, 120, 70));
      CanvasFillRect(c, x, y + 3, TILE, 1, Rgb(110, 70, 40));
      break;
    case '*':
      CanvasFillTriangle(c, x + 4, y + 1, x + 1, y + 4, x + 7, y + 4, Rgb(60, 220, 200));
      CanvasFillTriangle(c, x + 1, y + 4, x + 4, y + 7, x + 7, y + 4, Rgb(40, 160, 150));
      break;
  }
}

U0 Draw(Game *g, Canvas *c)
{
  CanvasClear(c, Rgb(40, 44, 78));

  // Only the tiles the camera can see, plus one for partial tiles.
  I64 tx0 = g->cam_x / TILE, ty0 = g->cam_y / TILE;
  for (I64 ty = ty0; ty <= ty0 + HEIGHT / TILE; ty++)
    for (I64 tx = tx0; tx <= tx0 + WIDTH / TILE; tx++)
      DrawTile(g, c, tx, ty, tx * TILE - g->cam_x, ty * TILE - g->cam_y);

  Player *p = &g->player;
  I64 sx = p->x / FP - 1 - g->cam_x, sy = p->y / FP - g->cam_y;
  for (I64 row = 0; row < TILE; row++)
    for (I64 col = 0; col < TILE; col++)
      if (g_hero_rows[row][col] != '.')
        CanvasPixel(c, sx + col, sy + row, HeroColor(g_hero_rows[row][col]));

  U8 hud[32];
  StrPrint(hud, "Gems %d/%d", g->gems, g->gems_total);
  FontDrawText(c, 5, 5, hud, Rgb(0, 0, 0));
  FontDrawText(c, 4, 4, hud, Rgb(240, 240, 250));
}

I32 RenderToFile(Game *g, U8 *path)
{
  Input in;
  in.dx = 1;
  in.jump = TRUE;
  for (I64 t = 0; t < 2000; t += 16)
    Update(g, &in, 16);

  Canvas c;
  if (!CanvasInit(&c, WIDTH, HEIGHT)) {
    "out of memory\n";
    return 1;
  }
  Draw(g, &c);
  Bool ok = CanvasSavePpm(&c, path);
  CanvasFree(&c);
  if (!ok) {
    "could not write %s\n", path;
    return 1;
  }
  "wrote %s, camera at (%d, %d)\n", path, g->cam_x, g->cam_y;
  return 0;
}

I32 Main(I32 argc, U8 **argv)
{
  Game *g = &g_game;
  LoadLevel(g);
  Respawn(g);
  UpdateCamera(g);
  if (argc > 2 && !StrCmp(argv[1], "--ppm"))
    return RenderToFile(g, argv[2]);

  Screen screen;
  if (!ScreenOpen(&screen, "HolyC tilemap", WIDTH, HEIGHT, SCALE))
    return 1;

  Input in;
  while (SdlPumpEvents() && !SdlKeyDown(SC_ESCAPE)) {
    in.dx = 0;
    if (SdlKeyDown(SC_LEFT) || SdlKeyDown(SC_A))
      in.dx--;
    if (SdlKeyDown(SC_RIGHT) || SdlKeyDown(SC_D))
      in.dx++;
    in.jump = SdlKeyDown(SC_SPACE) || SdlKeyDown(SC_UP) || SdlKeyDown(SC_W);

    Update(g, &in, ScreenFrameMs(&screen));
    Draw(g, &screen.canvas);
    ScreenPresent(&screen);
  }

  ScreenClose(&screen);
  return 0;
}
