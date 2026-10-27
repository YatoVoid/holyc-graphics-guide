// Window, frame loop and input using SDL2's 2D renderer directly.
// SDL does the drawing here; HolyC only decides what goes where.
//
//   ./sdl_example              open a window; arrow keys or WASD move the
//                              white box, hold the left mouse button to
//                              drag the orange one, Esc quits
//   ./sdl_example --ppm a.ppm  draw three seconds in with SDL's software
//                              renderer and no window, then save the frame

// canvas.HC is only used to write the --ppm file.
#include "../common/canvas.HC"
#include "../common/sdl2.HC"

#define WIDTH  800
#define HEIGHT 500
#define BOX    40
#define SPEED  300

extern "c" SdlSurface *SDL_CreateRGBSurfaceWithFormat(U32 flags, I32 w, I32 h, I32 depth,
                                                      U32 format);
extern "c" U0 *SDL_CreateSoftwareRenderer(SdlSurface *surface);
extern "c" I32 SDL_RenderReadPixels(U0 *renderer, SdlRect *rect, U32 format, U0 *pixels,
                                    I32 pitch);

class Box
{
  I64 x, y;
  I64 vx, vy;
};

U0 FillRect(U0 *renderer, I64 x, I64 y, I64 w, I64 h)
{
  SdlRect r;
  r.x = x;
  r.y = y;
  r.w = w;
  r.h = h;
  SDL_RenderFillRect(renderer, &r);
}

U0 Bounce(Box *b, I64 ms)
{
  b->x += b->vx * ms / 1000;
  b->y += b->vy * ms / 1000;
  if (b->x < 0 || b->x > WIDTH - BOX)
    b->vx = -b->vx;
  if (b->y < 0 || b->y > HEIGHT - BOX)
    b->vy = -b->vy;
  b->x = MaxI64(0, MinI64(b->x, WIDTH - BOX));
  b->y = MaxI64(0, MinI64(b->y, HEIGHT - BOX));
}

U0 Draw(U0 *renderer, Box *ball, I64 px, I64 py, I64 drag_x, I64 drag_y)
{
  // Clear, draw back to front.
  SDL_SetRenderDrawColor(renderer, 22, 24, 32, 255);
  SDL_RenderClear(renderer);

  SDL_SetRenderDrawColor(renderer, 40, 44, 58, 255);
  for (I64 x = 0; x < WIDTH; x += 50)
    SDL_RenderDrawLine(renderer, x, 0, x, HEIGHT);
  for (I64 y = 0; y < HEIGHT; y += 50)
    SDL_RenderDrawLine(renderer, 0, y, WIDTH, y);

  SDL_SetRenderDrawColor(renderer, 90, 200, 160, 255);
  FillRect(renderer, ball->x, ball->y, BOX, BOX);

  SDL_SetRenderDrawColor(renderer, 240, 150, 60, 255);
  FillRect(renderer, drag_x, drag_y, BOX, BOX);

  SDL_SetRenderDrawColor(renderer, 230, 230, 240, 255);
  FillRect(renderer, px, py, BOX, BOX);
}

U0 StartBall(Box *ball)
{
  ball->x = 100;
  ball->y = 80;
  ball->vx = 260;
  ball->vy = 190;
}

// The same drawing calls, into a surface in memory instead of a window.
// Three seconds of the ball in fixed 16 ms steps, the white box held left
// for one of them.
I32 RenderToFile(U8 *path)
{
  SdlSurface *surface = SDL_CreateRGBSurfaceWithFormat(0, WIDTH, HEIGHT, 32,
                                                       SDL_PIXELFORMAT_ARGB8888);
  if (!surface) {
    "SDL_CreateRGBSurfaceWithFormat failed: %s\n", SDL_GetError();
    return 1;
  }
  U0 *renderer = SDL_CreateSoftwareRenderer(surface);
  if (!renderer) {
    "SDL_CreateSoftwareRenderer failed: %s\n", SDL_GetError();
    SDL_FreeSurface(surface);
    return 1;
  }

  I64 px = WIDTH / 2 - BOX / 2, py = HEIGHT / 2 - BOX / 2;
  Box ball;
  StartBall(&ball);
  for (I64 t = 0; t < 3000; t += 16) {
    if (t < 1000)
      px -= SPEED * 16 / 1000;
    Bounce(&ball, 16);
  }
  Draw(renderer, &ball, px, py, 600, 300);

  Canvas c;
  Bool ok = CanvasInit(&c, WIDTH, HEIGHT);
  if (ok)
    ok = SDL_RenderReadPixels(renderer, NULL, SDL_PIXELFORMAT_ARGB8888, c.pixels,
                              WIDTH * sizeof(U32)) == 0;
  if (ok)
    ok = CanvasSavePpm(&c, path);
  if (ok)
    "wrote %s, ball at (%d, %d)\n", path, ball.x, ball.y;
  else
    "could not write %s\n", path;
  CanvasFree(&c);
  SDL_DestroyRenderer(renderer);
  SDL_FreeSurface(surface);
  return !ok;
}

I32 Main(I32 argc, U8 **argv)
{
  if (argc > 2 && !StrCmp(argv[1], "--ppm"))
    return RenderToFile(argv[2]);

  if (SDL_Init(SDL_INIT_VIDEO) != 0) {
    "SDL_Init failed: %s\n", SDL_GetError();
    return 1;
  }

  U0 *window = SDL_CreateWindow("HolyC + SDL2", SDL_WINDOWPOS_CENTERED,
                                SDL_WINDOWPOS_CENTERED, WIDTH, HEIGHT, SDL_WINDOW_SHOWN);
  if (!window) {
    "SDL_CreateWindow failed: %s\n", SDL_GetError();
    SDL_Quit();
    return 1;
  }

  U0 *renderer = SDL_CreateRenderer(window, -1,
                                    SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
  if (!renderer) {
    "SDL_CreateRenderer failed: %s\n", SDL_GetError();
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 1;
  }

  I64 px = WIDTH / 2 - BOX / 2, py = HEIGHT / 2 - BOX / 2;
  Box ball;
  StartBall(&ball);
  I64 drag_x = 600, drag_y = 300;

  U32 last = SDL_GetTicks();
  while (SdlPumpEvents() && !SdlKeyDown(SC_ESCAPE)) {
    U32 now = SDL_GetTicks();
    I64 ms = MinI64(now - last, 50);
    last = now;

    // Input: the keyboard state array says which keys are down right now.
    if (SdlKeyDown(SC_LEFT) || SdlKeyDown(SC_A))
      px -= SPEED * ms / 1000;
    if (SdlKeyDown(SC_RIGHT) || SdlKeyDown(SC_D))
      px += SPEED * ms / 1000;
    if (SdlKeyDown(SC_UP) || SdlKeyDown(SC_W))
      py -= SPEED * ms / 1000;
    if (SdlKeyDown(SC_DOWN) || SdlKeyDown(SC_S))
      py += SPEED * ms / 1000;
    px = MaxI64(0, MinI64(px, WIDTH - BOX));
    py = MaxI64(0, MinI64(py, HEIGHT - BOX));

    I32 mx, my;
    if (SDL_GetMouseState(&mx, &my) & SDL_BUTTON_LMASK) {
      drag_x = mx - BOX / 2;
      drag_y = my - BOX / 2;
    }

    Bounce(&ball, ms);
    Draw(renderer, &ball, px, py, drag_x, drag_y);
    SDL_RenderPresent(renderer);
  }

  SDL_DestroyRenderer(renderer);
  SDL_DestroyWindow(window);
  SDL_Quit();
  return 0;
}
