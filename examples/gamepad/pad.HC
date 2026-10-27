// Shows the state of the first game controller SDL finds: sticks,
// triggers, d-pad and buttons. Plug a controller in or out while it runs.
//
//   ./pad              open a window; Esc quits
//   ./pad --ppm a.ppm  attach a virtual controller with fixed inputs, save
//                      what it draws, then unplug and replug it

#include "../common/canvas.HC"
#include "../common/font.HC"
#include "../common/sdl2.HC"
#include "../common/screen.HC"

#define WIDTH  240
#define HEIGHT 160
#define SCALE  4

// Keeps the controller that's open, or opens the first one SDL has a
// mapping for. Calling this every frame handles plugging and unplugging
// without decoding SDL's device events.
U0 *PadFind(U0 *pad)
{
  if (pad && SDL_GameControllerGetAttached(pad))
    return pad;
  if (pad)
    SDL_GameControllerClose(pad);
  I64 n = SDL_NumJoysticks();
  for (I64 i = 0; i < n; i++)
    if (SDL_IsGameController(i))
      return SDL_GameControllerOpen(i);
  return NULL;
}

Bool PadDown(U0 *pad, I64 button)
{
  return SDL_GameControllerGetButton(pad, button) != 0;
}

I64 PadAxis(U0 *pad, I64 axis)
{
  return SDL_GameControllerGetAxis(pad, axis);
}

U32 Lit(Bool on)
{
  if (on)
    return Rgb(60, 220, 200);
  return Rgb(60, 56, 80);
}

U0 DrawButton(Canvas *c, I64 x, I64 y, Bool on, U8 *label)
{
  CanvasFillCircle(c, x, y, 6, Lit(on));
  FontDrawText(c, x - 2, y - 3, label, Rgb(24, 22, 34));
}

// Some sticks report a full square, so a corner is (32767, -32768). 11
// pixels per axis keeps even that inside the 16 pixel ring.
U0 DrawStick(Canvas *c, I64 x, I64 y, I64 ax, I64 ay, Bool clicked)
{
  CanvasFillCircle(c, x, y, 18, Rgb(60, 56, 80));
  CanvasFillCircle(c, x, y, 16, Rgb(24, 22, 34));
  CanvasFillCircle(c, x + ax * 11 / 32768, y + ay * 11 / 32768, 4, Lit(clicked));
}

// Triggers rest at 0 and fill the bar as they're pulled.
U0 DrawShoulder(Canvas *c, I64 x, Bool bumper, I64 trigger)
{
  CanvasFillRect(c, x, 22, 40, 6, Lit(bumper));
  CanvasRect(c, x, 31, 40, 6, Rgb(60, 56, 80));
  CanvasFillRect(c, x, 31, trigger * 40 / 32767, 6, Rgb(240, 200, 90));
}

U0 DrawPad(Canvas *c, U0 *pad)
{
  U8 *name = SDL_GameControllerName(pad);
  if (!name)
    name = "Unnamed controller";
  FontDrawText(c, (c->width - FontTextWidth(name)) / 2, 6, name, Rgb(240, 240, 250));

  DrawShoulder(c, 30, PadDown(pad, PAD_LEFTSHOULDER), PadAxis(pad, PAD_AXIS_TRIGGERLEFT));
  DrawShoulder(c, 170, PadDown(pad, PAD_RIGHTSHOULDER), PadAxis(pad, PAD_AXIS_TRIGGERRIGHT));

  DrawStick(c, 50, 72, PadAxis(pad, PAD_AXIS_LEFTX), PadAxis(pad, PAD_AXIS_LEFTY),
            PadDown(pad, PAD_LEFTSTICK));
  DrawStick(c, 150, 112, PadAxis(pad, PAD_AXIS_RIGHTX), PadAxis(pad, PAD_AXIS_RIGHTY),
            PadDown(pad, PAD_RIGHTSTICK));

  CanvasFillRect(c, 86, 98, 8, 8, Lit(PadDown(pad, PAD_DPAD_UP)));
  CanvasFillRect(c, 86, 118, 8, 8, Lit(PadDown(pad, PAD_DPAD_DOWN)));
  CanvasFillRect(c, 76, 108, 8, 8, Lit(PadDown(pad, PAD_DPAD_LEFT)));
  CanvasFillRect(c, 96, 108, 8, 8, Lit(PadDown(pad, PAD_DPAD_RIGHT)));

  CanvasFillRect(c, 100, 68, 10, 5, Lit(PadDown(pad, PAD_BACK)));
  CanvasFillCircle(c, 120, 70, 5, Lit(PadDown(pad, PAD_GUIDE)));
  CanvasFillRect(c, 130, 68, 10, 5, Lit(PadDown(pad, PAD_START)));

  DrawButton(c, 190, 58, PadDown(pad, PAD_Y), "Y");
  DrawButton(c, 190, 86, PadDown(pad, PAD_A), "A");
  DrawButton(c, 176, 72, PadDown(pad, PAD_X), "X");
  DrawButton(c, 204, 72, PadDown(pad, PAD_B), "B");

  U8 text[48];
  StrPrint(text, "L %d %d", PadAxis(pad, PAD_AXIS_LEFTX), PadAxis(pad, PAD_AXIS_LEFTY));
  FontDrawText(c, 6, 146, text, Rgb(200, 200, 220));
  StrPrint(text, "R %d %d", PadAxis(pad, PAD_AXIS_RIGHTX), PadAxis(pad, PAD_AXIS_RIGHTY));
  FontDrawText(c, c->width - 6 - FontTextWidth(text), 146, text, Rgb(200, 200, 220));
}

U0 Draw(Canvas *c, U0 *pad)
{
  CanvasClear(c, Rgb(24, 22, 34));
  if (pad) {
    DrawPad(c, pad);
    return;
  }
  U8 *msg = "Connect a controller";
  FontDrawText(c, (c->width - FontTextWidth(msg)) / 2, 76, msg, Rgb(200, 200, 220));
}

// SDL's virtual joysticks, for testing without a controller.
#define SDL_JOYSTICK_TYPE_GAMECONTROLLER 1

extern "c" I32 SDL_JoystickAttachVirtual(I32 type, I32 naxes, I32 nbuttons, I32 nhats);
extern "c" I32 SDL_JoystickDetachVirtual(I32 device_index);
extern "c" U0 *SDL_JoystickOpen(I32 device_index);
extern "c" U0 SDL_JoystickClose(U0 *joystick);
extern "c" I32 SDL_JoystickSetVirtualAxis(U0 *joystick, I32 axis, I16 value);
extern "c" I32 SDL_JoystickSetVirtualButton(U0 *joystick, I32 button, U8 value);

// SDL maps a virtual controller's joystick axis and button n to
// controller axis and button n, so the PAD_ constants address both.
I64 AttachVirtualPad()
{
  return SDL_JoystickAttachVirtual(SDL_JOYSTICK_TYPE_GAMECONTROLLER, 6, 15, 0);
}

I32 RenderToFile(U8 *path)
{
  if (SDL_Init(SDL_INIT_GAMECONTROLLER) != 0) {
    "SDL_Init failed: %s\n", SDL_GetError();
    return 1;
  }
  I64 index = AttachVirtualPad();
  U0 *joy = SDL_JoystickOpen(index);
  U0 *pad = PadFind(NULL);
  if (index < 0 || !joy || !pad) {
    "no virtual controller: %s\n", SDL_GetError();
    return 1;
  }

  // Set after the controller is open, because SDL can ignore a trigger's
  // position until it first changes. A virtual trigger's -32768..32767 is
  // rescaled to the controller's 0..32767, so the ends read 0 and 32767.
  SDL_JoystickSetVirtualAxis(joy, PAD_AXIS_LEFTX, -20000);
  SDL_JoystickSetVirtualAxis(joy, PAD_AXIS_LEFTY, 10000);
  SDL_JoystickSetVirtualAxis(joy, PAD_AXIS_RIGHTX, 32767);
  SDL_JoystickSetVirtualAxis(joy, PAD_AXIS_RIGHTY, -32768);
  SDL_JoystickSetVirtualAxis(joy, PAD_AXIS_TRIGGERLEFT, -32768);
  SDL_JoystickSetVirtualAxis(joy, PAD_AXIS_TRIGGERRIGHT, 32767);
  SDL_JoystickSetVirtualButton(joy, PAD_A, 1);
  SDL_JoystickSetVirtualButton(joy, PAD_Y, 1);
  SDL_JoystickSetVirtualButton(joy, PAD_DPAD_LEFT, 1);
  SDL_JoystickSetVirtualButton(joy, PAD_START, 1);
  SDL_JoystickSetVirtualButton(joy, PAD_LEFTSHOULDER, 1);
  SdlPumpEvents();

  Canvas c;
  if (!CanvasInit(&c, WIDTH, HEIGHT)) {
    "out of memory\n";
    return 1;
  }
  Draw(&c, pad);
  Bool ok = CanvasSavePpm(&c, path);
  CanvasFree(&c);
  if (!ok) {
    "could not write %s\n", path;
    return 1;
  }
  "wrote %s\n", path;

  SDL_JoystickClose(joy);
  SDL_JoystickDetachVirtual(index);
  SdlPumpEvents();
  pad = PadFind(pad);
  if (pad) {
    "still connected after unplugging\n";
    return 1;
  }
  AttachVirtualPad();
  SdlPumpEvents();
  pad = PadFind(pad);
  if (!pad) {
    "not found after plugging back in\n";
    return 1;
  }
  "unplugged and found again\n";
  SDL_GameControllerClose(pad);
  return 0;
}

I32 Main(I32 argc, U8 **argv)
{
  if (argc > 2 && !StrCmp(argv[1], "--ppm"))
    return RenderToFile(argv[2]);

  Screen screen;
  if (!ScreenOpen(&screen, "HolyC gamepad", WIDTH, HEIGHT, SCALE))
    return 1;
  if (SDL_Init(SDL_INIT_GAMECONTROLLER) != 0) {
    "SDL_Init failed: %s\n", SDL_GetError();
    ScreenClose(&screen);
    return 1;
  }

  U0 *pad = NULL;
  while (SdlPumpEvents() && !SdlKeyDown(SC_ESCAPE)) {
    pad = PadFind(pad);
    Draw(&screen.canvas, pad);
    ScreenPresent(&screen);
  }

  if (pad)
    SDL_GameControllerClose(pad);
  ScreenClose(&screen);
  return 0;
}
