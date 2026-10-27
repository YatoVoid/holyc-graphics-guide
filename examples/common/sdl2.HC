// The subset of SDL2 the examples use, declared for HolyC.
// Signatures follow SDL2's headers: int -> I32, Uint32 -> U32,
// pointers to opaque SDL types -> U0 *.

#link <SDL2>

#define SDL_INIT_AUDIO 0x00000010
#define SDL_INIT_VIDEO 0x00000020
#define SDL_INIT_GAMECONTROLLER 0x00002000

#define SDL_WINDOWPOS_CENTERED 0x2FFF0000
#define SDL_WINDOW_OPENGL      0x00000002
#define SDL_WINDOW_SHOWN       0x00000004
#define SDL_WINDOW_HIDDEN      0x00000008

#define SDL_RENDERER_ACCELERATED  0x00000002
#define SDL_RENDERER_PRESENTVSYNC 0x00000004

#define SDL_PIXELFORMAT_ARGB8888    0x16362004
#define SDL_TEXTUREACCESS_STREAMING 1

#define SDL_QUIT        0x100
#define SDL_EVENT_BYTES 64

#define SDL_BUTTON_LMASK 1

// AUDIO_S16LSB. Every platform hcc targets is little-endian.
#define AUDIO_S16SYS 0x8010

#define SDL_GL_DOUBLEBUFFER          5
#define SDL_GL_DEPTH_SIZE            6
#define SDL_GL_CONTEXT_MAJOR_VERSION 17
#define SDL_GL_CONTEXT_MINOR_VERSION 18
#define SDL_GL_CONTEXT_FLAGS         20
#define SDL_GL_CONTEXT_PROFILE_MASK  21
#define SDL_GL_CONTEXT_PROFILE_CORE  1
#define SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG 2

// SDL_GameControllerAxis. Sticks run from -32768 to 32767, with up and
// left negative; triggers from 0 to 32767.
#define PAD_AXIS_LEFTX        0
#define PAD_AXIS_LEFTY        1
#define PAD_AXIS_RIGHTX       2
#define PAD_AXIS_RIGHTY       3
#define PAD_AXIS_TRIGGERLEFT  4
#define PAD_AXIS_TRIGGERRIGHT 5

// SDL_GameControllerButton. Named by position on an Xbox pad: A is the
// bottom face button whatever the controller prints on it.
#define PAD_A              0
#define PAD_B              1
#define PAD_X              2
#define PAD_Y              3
#define PAD_BACK           4
#define PAD_GUIDE          5
#define PAD_START          6
#define PAD_LEFTSTICK      7
#define PAD_RIGHTSTICK     8
#define PAD_LEFTSHOULDER   9
#define PAD_RIGHTSHOULDER  10
#define PAD_DPAD_UP        11
#define PAD_DPAD_DOWN      12
#define PAD_DPAD_LEFT      13
#define PAD_DPAD_RIGHT     14

// Scancodes are physical key positions, not characters.
#define SC_A      4
#define SC_D      7
#define SC_S      22
#define SC_W      26
#define SC_ESCAPE 41
#define SC_SPACE  44
#define SC_RIGHT  79
#define SC_LEFT   80
#define SC_DOWN   81
#define SC_UP     82

// Matches SDL_Rect: four C ints.
class SdlRect
{
  I32 x, y, w, h;
};

// The start of SDL_Surface, which is all a program needs to read: size,
// row pitch in bytes, and the pixels. The padding fields make the C
// alignment explicit. Only ever use it through a pointer SDL returned.
class SdlSurface
{
  U32 flags;
  U32 pad0;
  U0 *format;
  I32 w, h;
  I32 pitch;
  I32 pad1;
  U0 *pixels;
};

// Matches SDL_AudioSpec. Leave callback NULL to use SDL_QueueAudio.
class SdlAudioSpec
{
  I32 freq;
  U16 format;
  U8 channels;
  U8 silence;
  U16 samples;
  U16 padding;
  U32 size;
  U0 *callback;
  U0 *userdata;
};

extern "c" I32 SDL_Init(U32 flags);
extern "c" U0 SDL_Quit();
extern "c" U8 *SDL_GetError();
extern "c" U0 *SDL_CreateWindow(U8 *title, I32 x, I32 y, I32 w, I32 h, U32 flags);
extern "c" U0 SDL_DestroyWindow(U0 *window);
extern "c" U0 SDL_SetWindowTitle(U0 *window, U8 *title);

extern "c" U0 *SDL_CreateRenderer(U0 *window, I32 index, U32 flags);
extern "c" U0 SDL_DestroyRenderer(U0 *renderer);
extern "c" I32 SDL_SetRenderDrawColor(U0 *renderer, U8 r, U8 g, U8 b, U8 a);
extern "c" I32 SDL_RenderClear(U0 *renderer);
extern "c" I32 SDL_RenderFillRect(U0 *renderer, SdlRect *rect);
extern "c" I32 SDL_RenderDrawLine(U0 *renderer, I32 x0, I32 y0, I32 x1, I32 y1);
extern "c" U0 SDL_RenderPresent(U0 *renderer);

extern "c" U0 *SDL_CreateTexture(U0 *renderer, U32 format, I32 access, I32 w, I32 h);
extern "c" U0 SDL_DestroyTexture(U0 *texture);
extern "c" I32 SDL_UpdateTexture(U0 *texture, SdlRect *rect, U0 *pixels, I32 pitch);
extern "c" I32 SDL_RenderCopy(U0 *renderer, U0 *texture, SdlRect *src, SdlRect *dst);

extern "c" SdlSurface *SDL_ConvertSurfaceFormat(SdlSurface *src, U32 format, U32 flags);
extern "c" U0 SDL_FreeSurface(SdlSurface *surface);

extern "c" I32 SDL_PollEvent(U0 *event);
extern "c" U8 *SDL_GetKeyboardState(I32 *numkeys);
extern "c" U32 SDL_GetMouseState(I32 *x, I32 *y);
extern "c" U32 SDL_GetTicks();
extern "c" U0 SDL_Delay(U32 ms);

extern "c" I32 SDL_NumJoysticks();
extern "c" I32 SDL_IsGameController(I32 joystick_index);
extern "c" U0 *SDL_GameControllerOpen(I32 joystick_index);
extern "c" U0 SDL_GameControllerClose(U0 *pad);
extern "c" I32 SDL_GameControllerGetAttached(U0 *pad);
extern "c" U8 *SDL_GameControllerName(U0 *pad);
extern "c" U8 SDL_GameControllerGetButton(U0 *pad, I32 button);
extern "c" I16 SDL_GameControllerGetAxis(U0 *pad, I32 axis);

extern "c" U32 SDL_OpenAudioDevice(U8 *device, I32 iscapture, SdlAudioSpec *desired,
                                   SdlAudioSpec *obtained, I32 allowed_changes);
extern "c" U0 SDL_PauseAudioDevice(U32 dev, I32 pause_on);
extern "c" I32 SDL_QueueAudio(U32 dev, U0 *data, U32 len);
extern "c" U32 SDL_GetQueuedAudioSize(U32 dev);
extern "c" U0 SDL_ClearQueuedAudio(U32 dev);
extern "c" U0 SDL_CloseAudioDevice(U32 dev);

extern "c" I32 SDL_GL_SetAttribute(I32 attr, I32 value);
extern "c" U0 *SDL_GL_CreateContext(U0 *window);
extern "c" U0 SDL_GL_DeleteContext(U0 *context);
extern "c" I32 SDL_GL_SetSwapInterval(I32 interval);
extern "c" U0 SDL_GL_SwapWindow(U0 *window);
extern "c" U0 SDL_GL_GetDrawableSize(U0 *window, I32 *w, I32 *h);

// Drains the event queue. Returns FALSE once the window was closed.
// SDL_Event is a 56-byte union; the first 4 bytes are always the type,
// which is all we need here.
Bool SdlPumpEvents()
{
  U8 event[SDL_EVENT_BYTES];
  Bool running = TRUE;
  while (SDL_PollEvent(event)) {
    U32 *type = event;
    if (*type == SDL_QUIT)
      running = FALSE;
  }
  return running;
}

Bool SdlKeyDown(I64 scancode)
{
  U8 *keys = SDL_GetKeyboardState(NULL);
  return keys[scancode] != 0;
}
