// TempleOS's Demo/Graphics/Bounce.HC, ported to hcc and SDL2. Sixteen
// points, one per palette color, bounce around the window and leave
// trails. docs/templeos-porting.md goes through every change.
//
//   ./bounce              open a window; Esc quits
//   ./bounce --ppm a.ppm  run 20000 steps with no window and save the result

#include "../common/canvas.HC"
#include "../common/sdl2.HC"
#include "../common/screen.HC"

#define WIDTH  640
#define HEIGHT 480

#define I32_MAX 0x7FFFFFFF
#define PI      3.14159265358979

// The original moves every point once per Yield, which runs as fast as
// the scheduler allows. Here the window shows a frame every 1/60 s, so
// each frame takes several steps.
#define STEPS_PER_FRAME 32

// TempleOS's gr_palette_std, indexed by its color constants: BLACK, BLUE,
// GREEN, CYAN, RED, PURPLE, BROWN, LTGRAY, DKGRAY, LTBLUE, LTGREEN,
// LTCYAN, LTRED, LTPURPLE, YELLOW, WHITE.
U32 g_palette[16] = {
  0xFF000000, 0xFF0000AA, 0xFF00AA00, 0xFF00AAAA,
  0xFFAA0000, 0xFFAA00AA, 0xFFAA5500, 0xFFAAAAAA,
  0xFF555555, 0xFF5555FF, 0xFF55FF55, 0xFF55FFFF,
  0xFFFF5555, 0xFFFF55FF, 0xFFFFFF55, 0xFFFFFFFF,
};

// Positions are 32.32 fixed point: the pixel is the top 32 bits.
I64 x[16];
I64 y[16];
I64 dx[16];
I64 dy[16];

// Seeded in Init rather than here: see "Initialised globals and Main's
// arguments" in docs/compiler-quirks.md.
U64 g_seed;

// TempleOS's Rand returns an F64 in [0, 1). hcc has none, so this is a
// small generator with a fixed seed: every run draws the same pattern.
// The mask keeps the top 53 bits positive; see "Unsigned 64-bit shifts
// and conversions" in docs/compiler-quirks.md.
F64 Rand()
{
  g_seed = g_seed * 6364136223846793005 + 1442695040888963407;
  F64 r = (g_seed >> 11) & 0x1FFFFFFFFFFFFF;
  return r / 9007199254740992.0;
}

U0 Init()
{
  I64 i;
  F64 angle;
  g_seed = 1;
  MemSet(x, 0, sizeof(x));
  MemSet(y, 0, sizeof(y));
  for (i = 0; i < 16; i++) {
    angle = Rand() * 2 * PI;
    dx[i] = I32_MAX * cos(angle);
    dy[i] = I32_MAX * sin(angle);
  }
}

U0 Step(Canvas *c)
{
  I64 i;
  for (i = 0; i < 16; i++) {
    CanvasPixel(c, x[i] >> 32, y[i] >> 32, g_palette[i]);
    x[i] += dx[i];
    y[i] += dy[i];
    if (!(0 <= x[i] < c->width << 32)) {
      x[i] -= dx[i];
      dx[i] = -dx[i];
    }
    if (!(0 <= y[i] < c->height << 32)) {
      y[i] -= dy[i];
      dy[i] = -dy[i];
    }
  }
}

I32 RenderToFile(U8 *path)
{
  Canvas c;
  if (!CanvasInit(&c, WIDTH, HEIGHT)) {
    "out of memory\n";
    return 1;
  }
  CanvasClear(&c, g_palette[15]);
  for (I64 n = 0; n < 20000; n++)
    Step(&c);
  Bool ok = CanvasSavePpm(&c, path);
  CanvasFree(&c);
  if (!ok) {
    "could not write %s\n", path;
    return 1;
  }
  "wrote %s\n", path;
  return 0;
}

I32 Main(I32 argc, U8 **argv)
{
  Init;
  if (argc > 2 && !StrCmp(argv[1], "--ppm"))
    return RenderToFile(argv[2]);

  Screen screen;
  if (!ScreenOpen(&screen, "Bounce", WIDTH, HEIGHT, 1))
    return 1;

  // A TempleOS window's document is white, and DCAlias draws on top of it
  // without ever clearing, which is what leaves the trails.
  CanvasClear(&screen.canvas, g_palette[15]);
  while (SdlPumpEvents() && !SdlKeyDown(SC_ESCAPE)) {
    for (I64 n = 0; n < STEPS_PER_FRAME; n++)
      Step(&screen.canvas);
    ScreenPresent(&screen);
  }

  ScreenClose(&screen);
  return 0;
}
