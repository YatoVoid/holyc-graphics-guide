// Draws a small scene into a software framebuffer and saves it as a PPM
// image. No window and no libraries beyond HolyC's own runtime.
//
//   hcc draw.HC -o draw && ./draw scene.ppm

#include "../common/canvas.HC"

#define WIDTH  320
#define HEIGHT 200

U0 DrawSky(Canvas *c)
{
  for (I64 y = 0; y < c->height; y++) {
    I64 t = y * 255 / c->height;
    U32 color = Rgb(20 + t / 4, 30 + t / 3, 80 + t / 2);
    CanvasFillRect(c, 0, y, c->width, 1, color);
  }
}

U0 DrawHills(Canvas *c)
{
  CanvasFillTriangle(c, -40, 200, 90, 110, 220, 200, Rgb(40, 90, 60));
  CanvasFillTriangle(c, 120, 200, 250, 120, 380, 200, Rgb(30, 75, 50));
  CanvasFillRect(c, 0, 170, c->width, 30, Rgb(50, 110, 60));
}

U0 DrawHouse(Canvas *c, I64 x, I64 y)
{
  CanvasFillRect(c, x, y, 60, 40, Rgb(180, 150, 110));
  CanvasRect(c, x, y, 60, 40, Rgb(60, 40, 30));
  CanvasFillTriangle(c, x - 6, y, x + 30, y - 26, x + 66, y, Rgb(150, 50, 40));
  CanvasFillRect(c, x + 24, y + 18, 12, 22, Rgb(90, 60, 40));
  CanvasFillRect(c, x + 8, y + 10, 10, 10, Rgb(250, 230, 140));
  CanvasFillRect(c, x + 42, y + 10, 10, 10, Rgb(250, 230, 140));
}

U0 DrawSunRays(Canvas *c, I64 cx, I64 cy)
{
  U32 ray = Rgb(255, 220, 120);
  CanvasLine(c, cx - 30, cy, cx - 20, cy, ray);
  CanvasLine(c, cx + 20, cy, cx + 30, cy, ray);
  CanvasLine(c, cx, cy - 30, cx, cy - 20, ray);
  CanvasLine(c, cx, cy + 20, cx, cy + 30, ray);
  CanvasLine(c, cx - 21, cy - 21, cx - 14, cy - 14, ray);
  CanvasLine(c, cx + 14, cy + 14, cx + 21, cy + 21, ray);
  CanvasLine(c, cx + 14, cy - 14, cx + 21, cy - 21, ray);
  CanvasLine(c, cx - 21, cy + 21, cx - 14, cy + 14, ray);
}

I32 Main(I32 argc, U8 **argv)
{
  U8 *path = "draw.ppm";
  if (argc > 1)
    path = argv[1];

  Canvas c;
  if (!CanvasInit(&c, WIDTH, HEIGHT)) {
    "out of memory\n";
    return 1;
  }

  DrawSky(&c);
  CanvasFillCircle(&c, 250, 50, 14, Rgb(255, 210, 90));
  DrawSunRays(&c, 250, 50);
  DrawHills(&c);
  DrawHouse(&c, 60, 132);

  if (!CanvasSavePpm(&c, path)) {
    "could not write %s\n", path;
    CanvasFree(&c);
    return 1;
  }
  "wrote %s (%dx%d)\n", path, c.width, c.height;
  CanvasFree(&c);
  return 0;
}
