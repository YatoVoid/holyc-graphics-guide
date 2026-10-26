// Square-wave beeps through SDL_QueueAudio. There's no audio callback:
// the program hands SDL finished blocks of samples and SDL plays them in
// order on its own thread. Requires sdl2.HC first.

#define AUDIO_RATE    48000
#define AUDIO_FADE_MS 4

class Audio
{
  U32 device;
  I64 volume;
};

Bool AudioOpen(Audio *a, I64 volume = 3000)
{
  MemSet(a, 0, sizeof(Audio));
  a->volume = volume;

  if (SDL_Init(SDL_INIT_AUDIO) != 0) {
    "SDL_Init failed: %s\n", SDL_GetError();
    return FALSE;
  }

  SdlAudioSpec want;
  MemSet(&want, 0, sizeof(SdlAudioSpec));
  want.freq = AUDIO_RATE;
  want.format = AUDIO_S16SYS;
  want.channels = 1;
  want.samples = 1024;

  // 0 for allowed_changes: SDL converts to whatever the hardware wants,
  // so the samples below are always 48 kHz mono 16-bit.
  U32 device = SDL_OpenAudioDevice(NULL, 0, &want, NULL, 0);
  if (!device) {
    "SDL_OpenAudioDevice failed: %s\n", SDL_GetError();
    return FALSE;
  }
  a->device = device;
  SDL_PauseAudioDevice(device, 0);
  return TRUE;
}

// Queues `ms` of a square wave at `freq` Hz, or silence when freq is 0.
// Returns immediately; the sound plays after anything already queued.
U0 AudioBeep(Audio *a, I64 freq, I64 ms)
{
  I64 n = AUDIO_RATE * ms / 1000;
  I64 fade = AUDIO_RATE * AUDIO_FADE_MS / 1000;
  I16 *samples = MAlloc(n * sizeof(I16));

  for (I64 i = 0; i < n; i++) {
    // A short ramp at each end. Starting or stopping at full volume
    // makes an audible click.
    I64 level = a->volume;
    if (freq == 0)
      level = 0;
    if (i < fade)
      level = level * i / fade;
    if (n - i < fade)
      level = level * (n - i) / fade;

    // `freq` full cycles per second is 2 * freq half-cycles: high on
    // the even ones, low on the odd ones.
    if ((i * freq * 2 / AUDIO_RATE) % 2)
      level = 0 - level;
    samples[i] = level;
  }

  SDL_QueueAudio(a->device, samples, n * sizeof(I16));
  Free(samples);
}

// Milliseconds of sound still waiting to play.
I64 AudioQueuedMs(Audio *a)
{
  I64 bytes = SDL_GetQueuedAudioSize(a->device);
  return bytes / sizeof(I16) * 1000 / AUDIO_RATE;
}

// Blocks until everything queued has been handed to the hardware.
U0 AudioWait(Audio *a)
{
  while (SDL_GetQueuedAudioSize(a->device) > 0)
    SDL_Delay(10);
}

U0 AudioClose(Audio *a)
{
  if (a->device)
    SDL_CloseAudioDevice(a->device);
  a->device = 0;
}
