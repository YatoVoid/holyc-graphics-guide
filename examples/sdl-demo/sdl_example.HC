// Window, frame loop and input using SDL2's 2D renderer directly.
// SDL does the drawing here; HolyC only decides what goes where.
//
// Arrow keys or WASD move the box. Hold the left mouse button to drag
// the orange box. Esc or closing the window quits.

#include "../common/sdl2.HC"

#define WIDTH  800
#define HEIGHT 500
#define BOX    40
#define SPEED  300

I64 MinI64(I64 a, I64 b)
{
  if (a < b)
    return a;
  return b;
}

I64 MaxI64(I64 a, I64 b)
{
  if (a > b)
    return a;
  return b;
}

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

I32 Main()
{
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
  ball.x = 100;
  ball.y = 80;
  ball.vx = 260;
  ball.vy = 190;
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

    // Draw: clear, draw back to front, present.
    SDL_SetRenderDrawColor(renderer, 22, 24, 32, 255);
    SDL_RenderClear(renderer);

    SDL_SetRenderDrawColor(renderer, 40, 44, 58, 255);
    for (I64 x = 0; x < WIDTH; x += 50)
      SDL_RenderDrawLine(renderer, x, 0, x, HEIGHT);
    for (I64 y = 0; y < HEIGHT; y += 50)
      SDL_RenderDrawLine(renderer, 0, y, WIDTH, y);

    SDL_SetRenderDrawColor(renderer, 90, 200, 160, 255);
    FillRect(renderer, ball.x, ball.y, BOX, BOX);

    SDL_SetRenderDrawColor(renderer, 240, 150, 60, 255);
    FillRect(renderer, drag_x, drag_y, BOX, BOX);

    SDL_SetRenderDrawColor(renderer, 230, 230, 240, 255);
    FillRect(renderer, px, py, BOX, BOX);

    SDL_RenderPresent(renderer);
  }

  SDL_DestroyRenderer(renderer);
  SDL_DestroyWindow(window);
  SDL_Quit();
  return 0;
}
