// Draws text into a canvas with the bitmap font in common/font.HC and
// saves it as a PPM image.
//
//   hcc text.HC -o text && ./text text.ppm

#include "../common/canvas.HC"
#include "../common/font.HC"

#define WIDTH  320
#define HEIGHT 200

U0 DrawCentered(Canvas *c, I64 y, U8 *text, U32 color, I64 scale)
{
  I64 x = (c->width - FontTextWidth(text, scale)) / 2;
  FontDrawText(c, x + scale, y + scale, text, Rgb(0, 0, 0), scale);
  FontDrawText(c, x, y, text, color, scale);
}

I32 Main(I32 argc, U8 **argv)
{
  U8 *path = "text.ppm";
  if (argc > 1)
    path = argv[1];

  Canvas c;
  if (!CanvasInit(&c, WIDTH, HEIGHT)) {
    "out of memory\n";
    return 1;
  }

  CanvasClear(&c, Rgb(24, 22, 34));
  DrawCentered(&c, 14, "HolyC text", Rgb(240, 200, 90), 3);

  FontDrawText(&c, 16, 56, "ABCDEFGHIJKLMNOPQRSTUVWXYZ\n0123456789 .,:!?'-+/()%", Rgb(200, 200, 220));

  U8 score[64];
  StrPrint(score, "Score: %d  Best: %d", 1250, 9001);
  FontDrawText(&c, 16, 84, score, Rgb(60, 220, 200), 2);

  CanvasFillRect(&c, 16, 120, 288, 44, Rgb(40, 36, 58));
  CanvasRect(&c, 16, 120, 288, 44, Rgb(120, 60, 150));
  FontDrawText(&c, 26, 130, "A bat blocks the way.\nPress Space to fight,\nor run (it's faster).", Rgb(230, 230, 240));

  if (!CanvasSavePpm(&c, path)) {
    "could not write %s\n", path;
    CanvasFree(&c);
    return 1;
  }
  "wrote %s (%dx%d)\n", path, c.width, c.height;
  CanvasFree(&c);
  return 0;
}
