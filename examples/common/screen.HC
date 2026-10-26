// Shows a Canvas in a window. The canvas is copied into an SDL texture
// each frame and scaled up, so you get chunky pixels and never deal with
// the GPU directly. Requires sdl2.HC and canvas.HC first.

class Screen
{
  U0 *window;
  U0 *renderer;
  U0 *texture;
  I64 scale;
  Canvas canvas;
  U32 last_ticks;
};

Bool ScreenOpen(Screen *s, U8 *title, I64 width, I64 height, I64 scale)
{
  MemSet(s, 0, sizeof(Screen));
  s->scale = scale;

  if (SDL_Init(SDL_INIT_VIDEO) != 0) {
    "SDL_Init failed: %s\n", SDL_GetError();
    return FALSE;
  }
  s->window = SDL_CreateWindow(title, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
                               width * scale, height * scale, SDL_WINDOW_SHOWN);
  if (!s->window) {
    "SDL_CreateWindow failed: %s\n", SDL_GetError();
    return FALSE;
  }
  s->renderer = SDL_CreateRenderer(s->window, -1,
                                   SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
  if (!s->renderer) {
    "SDL_CreateRenderer failed: %s\n", SDL_GetError();
    return FALSE;
  }
  s->texture = SDL_CreateTexture(s->renderer, SDL_PIXELFORMAT_ARGB8888,
                                 SDL_TEXTUREACCESS_STREAMING, width, height);
  if (!s->texture) {
    "SDL_CreateTexture failed: %s\n", SDL_GetError();
    return FALSE;
  }
  if (!CanvasInit(&s->canvas, width, height)) {
    "out of memory\n";
    return FALSE;
  }
  s->last_ticks = SDL_GetTicks();
  return TRUE;
}

U0 ScreenClose(Screen *s)
{
  CanvasFree(&s->canvas);
  if (s->texture)
    SDL_DestroyTexture(s->texture);
  if (s->renderer)
    SDL_DestroyRenderer(s->renderer);
  if (s->window)
    SDL_DestroyWindow(s->window);
  SDL_Quit();
}

U0 ScreenPresent(Screen *s)
{
  SDL_UpdateTexture(s->texture, NULL, s->canvas.pixels, s->canvas.width * sizeof(U32));
  SDL_RenderCopy(s->renderer, s->texture, NULL, NULL);
  SDL_RenderPresent(s->renderer);
}

// Milliseconds since the previous call, capped so a stall (dragging the
// window, a debugger break) doesn't teleport everything.
I64 ScreenFrameMs(Screen *s)
{
  U32 now = SDL_GetTicks();
  I64 ms = now - s->last_ticks;
  s->last_ticks = now;
  return MinI64(ms, 50);
}

// Mouse position in canvas pixels.
Bool ScreenMouse(Screen *s, I64 *x, I64 *y)
{
  I32 mx, my;
  U32 buttons = SDL_GetMouseState(&mx, &my);
  *x = mx / s->scale;
  *y = my / s->scale;
  return (buttons & SDL_BUTTON_LMASK) != 0;
}
