// SDL2_image: PNG, JPEG, GIF, BMP and more through one call. Requires
// sdl2.HC and canvas.HC first. Separate from sdl2.HC so only programs
// that load images link the extra library.

#link <SDL2_image>

extern "c" SdlSurface *IMG_Load(U8 *path);
extern "c" U0 IMG_Quit();

// Loads any format SDL2_image reads into a canvas. SDL first converts the
// image to ARGB8888, the canvas's own format, keeping its alpha. Rows in
// a surface can be padded, so they're copied one at a time using pitch.
Bool CanvasLoadImage(Canvas *c, U8 *path)
{
  SdlSurface *loaded = IMG_Load(path);
  if (!loaded) {
    "IMG_Load %s: %s\n", path, SDL_GetError();
    return FALSE;
  }
  SdlSurface *argb = SDL_ConvertSurfaceFormat(loaded, SDL_PIXELFORMAT_ARGB8888, 0);
  SDL_FreeSurface(loaded);
  if (!argb) {
    "SDL_ConvertSurfaceFormat: %s\n", SDL_GetError();
    return FALSE;
  }

  Bool ok = CanvasInit(c, argb->w, argb->h);
  if (ok) {
    U8 *row = argb->pixels;
    for (I64 y = 0; y < argb->h; y++) {
      MemCpy(c->pixels + y * c->width, row, argb->w * sizeof(U32));
      row += argb->pitch;
    }
  }
  SDL_FreeSurface(argb);
  return ok;
}
