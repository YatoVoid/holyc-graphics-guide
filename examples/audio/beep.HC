// Plays a few square-wave sounds with no window: a short tune, a coin
// pickup and a falling "hurt" sound. Everything is queued up front, then
// the program waits for the queue to drain.

#include "../common/sdl2.HC"
#include "../common/audio.HC"

#define NOTE_C5 523
#define NOTE_E5 659
#define NOTE_G5 784
#define NOTE_B5 988
#define NOTE_C6 1047
#define NOTE_E6 1319

// Pairs of frequency and length in ms. 0 Hz is a rest.
I64 g_tune[] = {
  NOTE_C5, 120, NOTE_E5, 120, NOTE_G5, 120, NOTE_C6, 240,
  0, 120,
  NOTE_G5, 120, NOTE_C6, 360,
};

U0 PlayCoin(Audio *a)
{
  AudioBeep(a, NOTE_B5, 60);
  AudioBeep(a, NOTE_E6, 180);
}

U0 PlayHurt(Audio *a)
{
  for (I64 freq = 400; freq >= 200; freq -= 100)
    AudioBeep(a, freq, 70);
}

I32 Main()
{
  Audio audio;
  if (!AudioOpen(&audio))
    return 1;

  I64 notes = sizeof(g_tune) / sizeof(I64) / 2;
  for (I64 i = 0; i < notes; i++)
    AudioBeep(&audio, g_tune[i * 2], g_tune[i * 2 + 1]);
  AudioBeep(&audio, 0, 300);
  PlayCoin(&audio);
  AudioBeep(&audio, 0, 300);
  PlayHurt(&audio);

  "queued %d ms of sound\n", AudioQueuedMs(&audio);
  AudioWait(&audio);
  // The queue empties when SDL takes the last block, which is a little
  // before the speaker finishes it.
  SDL_Delay(100);

  AudioClose(&audio);
  SDL_Quit();
  "done\n";
  return 0;
}
