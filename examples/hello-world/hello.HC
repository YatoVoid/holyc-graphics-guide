// The smallest useful HolyC program, plus a few language features you'll
// see in every other example.

class Player
{
  U8 *name;
  I64 hp;
  I64 x, y;
};

U0 Move(Player *p, I64 dx, I64 dy = 0)
{
  p->x += dx;
  p->y += dy;
}

U0 Main()
{
  // A string literal on its own is a print statement.
  "Hello from HolyC!\n";

  // With arguments it works like printf.
  Player p;
  p.name = "Terry";
  p.hp = 100;
  p.x = 0;
  p.y = 0;

  for (I64 i = 0; i < 3; i++)
    Move(&p, 2);
  Move(&p, 0, 5);

  "%s has %d hp and stands at (%d, %d)\n", p.name, p.hp, p.x, p.y;

  F64 speed = 2.5;
  "Floats print with %%f: %f\n", speed * 2;
}
