// A 5x7 bitmap font drawn into a Canvas. The glyphs are ASCII art, like
// the sprites in sprite-demo: eight glyphs per band, separated by a blank
// column, '#' for ink. Lowercase letters draw as uppercase.
//
// Needs canvas.HC included first.

#define FONT_W        5
#define FONT_H        7
#define FONT_ADVANCE  6
#define FONT_LINE     9
#define FONT_PER_BAND 8

U8 *g_font_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,:!?'-+/()%";

U8 *g_font_rows[] = {
  // A     B     C     D     E     F     G     H
  ".###. ####. .###. ####. ##### ##### .###. #...#",
  "#...# #...# #...# #...# #.... #.... #...# #...#",
  "#...# #...# #.... #...# #.... #.... #.... #...#",
  "##### ####. #.... #...# ####. ####. #.### #####",
  "#...# #...# #.... #...# #.... #.... #...# #...#",
  "#...# #...# #...# #...# #.... #.... #...# #...#",
  "#...# ####. .###. ####. ##### #.... .#### #...#",
  // I     J     K     L     M     N     O     P
  ".###. ..### #...# #.... #...# #...# .###. ####.",
  "..#.. ...#. #..#. #.... ##.## #...# #...# #...#",
  "..#.. ...#. #.#.. #.... #.#.# ##..# #...# #...#",
  "..#.. ...#. ##... #.... #.#.# #.#.# #...# ####.",
  "..#.. ...#. #.#.. #.... #...# #..## #...# #....",
  "..#.. #..#. #..#. #.... #...# #...# #...# #....",
  ".###. .##.. #...# ##### #...# #...# .###. #....",
  // Q     R     S     T     U     V     W     X
  ".###. ####. .#### ##### #...# #...# #...# #...#",
  "#...# #...# #.... ..#.. #...# #...# #...# #...#",
  "#...# #...# #.... ..#.. #...# #...# #...# .#.#.",
  "#...# ####. .###. ..#.. #...# #...# #.#.# ..#..",
  "#.#.# #.#.. ....# ..#.. #...# #...# #.#.# .#.#.",
  "#..#. #..#. ....# ..#.. #...# .#.#. #.#.# #...#",
  ".##.# #...# ####. ..#.. .###. ..#.. .#.#. #...#",
  // Y     Z     0     1     2     3     4     5
  "#...# ##### .###. ..#.. .###. ##### ...#. #####",
  "#...# ....# #...# .##.. #...# ...#. ..##. #....",
  ".#.#. ...#. #..## ..#.. ....# ..#.. .#.#. ####.",
  "..#.. ..#.. #.#.# ..#.. ...#. ...#. #..#. ....#",
  "..#.. .#... ##..# ..#.. ..#.. ....# ##### ....#",
  "..#.. #.... #...# ..#.. .#... #...# ...#. #...#",
  "..#.. ##### .###. .###. ##### .###. ...#. .###.",
  // 6     7     8     9     .     ,     :     !
  "..##. ##### .###. .###. ..... ..... ..... ..#..",
  ".#... ....# #...# #...# ..... ..... .##.. ..#..",
  "#.... ...#. #...# #...# ..... ..... .##.. ..#..",
  "####. ..#.. .###. .#### ..... ..... ..... ..#..",
  "#...# .#... #...# ....# ..... .##.. .##.. ..#..",
  "#...# .#... #...# ...#. .##.. ..#.. .##.. .....",
  ".###. .#... .###. .##.. .##.. .#... ..... ..#..",
  // ?     '     -     +     /     (     )     %
  ".###. ..#.. ..... ..... ..... ...#. .#... ##...",
  "#...# ..#.. ..... ..#.. ....# ..#.. ..#.. ##..#",
  "....# .#... ..... ..#.. ...#. .#... ...#. ...#.",
  "...#. ..... ##### ##### ..#.. .#... ...#. ..#..",
  "..#.. ..... ..... ..#.. .#... .#... ...#. .#...",
  "..... ..... ..... ..#.. #.... ..#.. ..#.. #..##",
  "..#.. ..... ..... ..... ..... ...#. .#... ...##",
};

// Index into g_font_chars, or -1 for a character the font doesn't have.
I64 FontGlyph(U8 ch)
{
  if (ch >= 'a' && ch <= 'z')
    ch = ch - 'a' + 'A';
  for (I64 i = 0; g_font_chars[i]; i++)
    if (g_font_chars[i] == ch)
      return i;
  return -1;
}

U0 FontDrawGlyph(Canvas *c, I64 x, I64 y, I64 glyph, U32 color, I64 scale)
{
  I64 first_row = (glyph / FONT_PER_BAND) * FONT_H;
  I64 first_col = (glyph % FONT_PER_BAND) * FONT_ADVANCE;
  for (I64 row = 0; row < FONT_H; row++) {
    U8 *line = g_font_rows[first_row + row];
    for (I64 col = 0; col < FONT_W; col++)
      if (line[first_col + col] == '#')
        CanvasFillRect(c, x + col * scale, y + row * scale, scale, scale, color);
  }
}

// Draws `text` with its top-left corner at (x, y). '\n' starts a new line.
// Spaces and unknown characters leave a gap.
U0 FontDrawText(Canvas *c, I64 x, I64 y, U8 *text, U32 color, I64 scale = 1)
{
  I64 pen_x = x;
  for (I64 i = 0; text[i]; i++) {
    if (text[i] == '\n') {
      pen_x = x;
      y += FONT_LINE * scale;
      continue;
    }
    I64 glyph = FontGlyph(text[i]);
    if (glyph >= 0)
      FontDrawGlyph(c, pen_x, y, glyph, color, scale);
    pen_x += FONT_ADVANCE * scale;
  }
}

// Width in pixels of the longest line, without the trailing gap.
I64 FontTextWidth(U8 *text, I64 scale = 1)
{
  I64 widest = 0, chars = 0;
  for (I64 i = 0; TRUE; i++) {
    if (text[i] == '\n' || !text[i]) {
      widest = MaxI64(widest, chars);
      chars = 0;
      if (!text[i])
        break;
    } else {
      chars++;
    }
  }
  if (widest == 0)
    return 0;
  return (widest * FONT_ADVANCE - 1) * scale;
}
