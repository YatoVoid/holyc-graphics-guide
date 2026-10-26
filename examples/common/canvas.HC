// A software framebuffer: an array of 32-bit ARGB pixels you draw into
// with plain HolyC, then save to a file or hand to SDL to show.
// Everything here uses integer math.

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

I64 AbsI64(I64 v)
{
  if (v < 0)
    return -v;
  return v;
}

class Canvas
{
  I64 width;
  I64 height;
  U32 *pixels;
};

U32 Rgb(I64 r, I64 g, I64 b)
{
  return 0xFF000000 | ((r & 0xFF) << 16) | ((g & 0xFF) << 8) | (b & 0xFF);
}

Bool CanvasInit(Canvas *c, I64 width, I64 height)
{
  c->width = width;
  c->height = height;
  c->pixels = CAlloc(width * height * sizeof(U32));
  if (!c->pixels)
    return FALSE;
  return TRUE;
}

U0 CanvasFree(Canvas *c)
{
  Free(c->pixels);
  c->pixels = NULL;
}

U0 CanvasClear(Canvas *c, U32 color)
{
  I64 n = c->width * c->height;
  for (I64 i = 0; i < n; i++)
    c->pixels[i] = color;
}

U0 CanvasPixel(Canvas *c, I64 x, I64 y, U32 color)
{
  if (x < 0 || y < 0 || x >= c->width || y >= c->height)
    return;
  c->pixels[y * c->width + x] = color;
}

U0 CanvasFillRect(Canvas *c, I64 x, I64 y, I64 w, I64 h, U32 color)
{
  I64 x0 = MaxI64(x, 0), y0 = MaxI64(y, 0);
  I64 x1 = MinI64(x + w, c->width), y1 = MinI64(y + h, c->height);
  for (I64 py = y0; py < y1; py++)
    for (I64 px = x0; px < x1; px++)
      c->pixels[py * c->width + px] = color;
}

U0 CanvasRect(Canvas *c, I64 x, I64 y, I64 w, I64 h, U32 color)
{
  CanvasFillRect(c, x, y, w, 1, color);
  CanvasFillRect(c, x, y + h - 1, w, 1, color);
  CanvasFillRect(c, x, y, 1, h, color);
  CanvasFillRect(c, x + w - 1, y, 1, h, color);
}

// Bresenham's line algorithm.
U0 CanvasLine(Canvas *c, I64 x0, I64 y0, I64 x1, I64 y1, U32 color)
{
  I64 dx = AbsI64(x1 - x0), dy = -AbsI64(y1 - y0);
  I64 sx = 1, sy = 1;
  if (x0 > x1)
    sx = -1;
  if (y0 > y1)
    sy = -1;
  I64 err = dx + dy;

  while (TRUE) {
    CanvasPixel(c, x0, y0, color);
    if (x0 == x1 && y0 == y1)
      break;
    I64 e2 = 2 * err;
    if (e2 >= dy) {
      err += dy;
      x0 += sx;
    }
    if (e2 <= dx) {
      err += dx;
      y0 += sy;
    }
  }
}

U0 CanvasFillCircle(Canvas *c, I64 cx, I64 cy, I64 r, U32 color)
{
  for (I64 y = -r; y <= r; y++)
    for (I64 x = -r; x <= r; x++)
      if (x * x + y * y <= r * r)
        CanvasPixel(c, cx + x, cy + y, color);
}

I64 EdgeSide(I64 ax, I64 ay, I64 bx, I64 by, I64 px, I64 py)
{
  return (bx - ax) * (py - ay) - (by - ay) * (px - ax);
}

// Fills every pixel whose centre is on the inside of all three edges.
// Works for either winding order.
U0 CanvasFillTriangle(Canvas *c, I64 x0, I64 y0, I64 x1, I64 y1, I64 x2, I64 y2, U32 color)
{
  I64 area = EdgeSide(x0, y0, x1, y1, x2, y2);
  if (area == 0)
    return;

  I64 min_x = MaxI64(MinI64(x0, MinI64(x1, x2)), 0);
  I64 max_x = MinI64(MaxI64(x0, MaxI64(x1, x2)), c->width - 1);
  I64 min_y = MaxI64(MinI64(y0, MinI64(y1, y2)), 0);
  I64 max_y = MinI64(MaxI64(y0, MaxI64(y1, y2)), c->height - 1);

  for (I64 y = min_y; y <= max_y; y++) {
    for (I64 x = min_x; x <= max_x; x++) {
      I64 w0 = EdgeSide(x1, y1, x2, y2, x, y);
      I64 w1 = EdgeSide(x2, y2, x0, y0, x, y);
      I64 w2 = EdgeSide(x0, y0, x1, y1, x, y);
      if (area > 0) {
        if (w0 >= 0 && w1 >= 0 && w2 >= 0)
          c->pixels[y * c->width + x] = color;
      } else {
        if (w0 <= 0 && w1 <= 0 && w2 <= 0)
          c->pixels[y * c->width + x] = color;
      }
    }
  }
}

// Writes a binary PPM (P6), which most image viewers and ImageMagick open.
Bool CanvasSavePpm(Canvas *c, U8 *path)
{
  U8 *header = MStrPrint("P6\n%d %d\n255\n", c->width, c->height);
  I64 header_len = StrLen(header);
  I64 size = header_len + c->width * c->height * 3;
  U8 *file = MAlloc(size);
  MemCpy(file, header, header_len);

  U8 *out = file + header_len;
  I64 n = c->width * c->height;
  for (I64 i = 0; i < n; i++) {
    U32 p = c->pixels[i];
    out[0] = (p >> 16) & 0xFF;
    out[1] = (p >> 8) & 0xFF;
    out[2] = p & 0xFF;
    out += 3;
  }

  Bool ok = FileWrite(path, file, size, O_CREAT | O_RDWR | O_TRUNC);
  Free(file);
  Free(header);
  return ok;
}

// Skips whitespace and '#' comments, then reads a decimal number.
// Returns -1 if there isn't one.
I64 PpmNumber(U8 *file, I64 size, I64 *pos)
{
  while (*pos < size) {
    U8 ch = file[*pos];
    if (ch == '#') {
      while (*pos < size && file[*pos] != '\n')
        *pos += 1;
    } else if (ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r') {
      *pos += 1;
    } else {
      break;
    }
  }
  I64 value = -1;
  while (*pos < size && file[*pos] >= '0' && file[*pos] <= '9') {
    if (value < 0)
      value = 0;
    value = value * 10 + file[*pos] - '0';
    *pos += 1;
  }
  return value;
}

// Reads a binary PPM (P6) with 8-bit channels: what CanvasSavePpm writes
// and what `magick in.png out.ppm` produces. Initialises `c`; free it with
// CanvasFree. Returns FALSE for a missing file or any other kind of PPM.
Bool CanvasLoadPpm(Canvas *c, U8 *path)
{
  I64 size = 0;
  U8 *file = FileRead(path, &size);
  if (!file)
    return FALSE;

  Bool ok = FALSE;
  I64 pos = 2;
  if (size > 2 && file[0] == 'P' && file[1] == '6') {
    I64 w = PpmNumber(file, size, &pos);
    I64 h = PpmNumber(file, size, &pos);
    I64 max = PpmNumber(file, size, &pos);
    // Exactly one whitespace byte separates the header from the pixels.
    pos++;
    if (w > 0 && h > 0 && max == 255 && pos + w * h * 3 <= size && CanvasInit(c, w, h)) {
      U8 *in = file + pos;
      for (I64 i = 0; i < w * h; i++) {
        c->pixels[i] = Rgb(in[0], in[1], in[2]);
        in += 3;
      }
      ok = TRUE;
    }
  }
  Free(file);
  return ok;
}

// Copies `src` onto `dst` with its top-left corner at (x, y). Pixels with
// alpha below half are skipped, so a PNG with a transparent background
// draws as a sprite. Canvas drawing functions always use full alpha.
U0 CanvasBlit(Canvas *dst, Canvas *src, I64 x, I64 y)
{
  for (I64 sy = 0; sy < src->height; sy++) {
    for (I64 sx = 0; sx < src->width; sx++) {
      U32 p = src->pixels[sy * src->width + sx];
      if ((p >> 24) >= 0x80)
        CanvasPixel(dst, x + sx, y + sy, p);
    }
  }
}
