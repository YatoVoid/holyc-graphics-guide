// Loads a PPM with HolyC's own reader and a PNG through SDL2_image, then
// draws them into a canvas and saves it. Run it from this folder so it
// finds bricks.ppm and slime.png.
//
//   hcc load.HC -o load && ./load scene.ppm

#include "../common/canvas.HC"
#include "../common/font.HC"
#include "../common/sdl2.HC"
#include "../common/sdl2_image.HC"

#define WIDTH  240
#define HEIGHT 160

I32 Main(I32 argc, U8 **argv)
{
  U8 *path = "load.ppm";
  if (argc > 1)
    path = argv[1];

  Canvas bricks;
  if (!CanvasLoadPpm(&bricks, "bricks.ppm")) {
    "could not read bricks.ppm\n";
    return 1;
  }
  Canvas slime;
  if (!CanvasLoadImage(&slime, "slime.png")) {
    CanvasFree(&bricks);
    return 1;
  }
  "bricks.ppm %dx%d, slime.png %dx%d\n", bricks.width, bricks.height, slime.width, slime.height;

  Canvas c;
  if (!CanvasInit(&c, WIDTH, HEIGHT)) {
    "out of memory\n";
    return 1;
  }
  CanvasClear(&c, Rgb(24, 22, 34));
  for (I64 x = 0; x < WIDTH; x += bricks.width) {
    CanvasBlit(&c, &bricks, x, HEIGHT - bricks.height * 2);
    CanvasBlit(&c, &bricks, x, HEIGHT - bricks.height);
  }
  for (I64 i = 0; i < 5; i++)
    CanvasBlit(&c, &slime, 30 + i * 40, HEIGHT - bricks.height * 2 - slime.height + 2);

  FontDrawText(&c, 8, 8, "bricks.ppm: HolyC PPM reader", Rgb(200, 200, 220));
  FontDrawText(&c, 8, 20, "slime.png: SDL2 image", Rgb(60, 220, 200));

  Bool ok = CanvasSavePpm(&c, path);
  if (ok)
    "wrote %s (%dx%d)\n", path, c.width, c.height;
  else
    "could not write %s\n", path;
  CanvasFree(&c);
  CanvasFree(&slime);
  CanvasFree(&bricks);
  IMG_Quit();
  if (!ok)
    return 1;
  return 0;
}
