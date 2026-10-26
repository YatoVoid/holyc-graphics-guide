# Sound

`examples/audio/beep.HC` plays a short tune, a coin pickup and a "hurt" sound, then exits. It opens no window. The reusable part is `examples/common/audio.HC`, about 90 lines on top of a few SDL2 declarations.

```sh
cd examples/audio && hcc -jit beep.HC
```

## Queueing instead of callbacks

SDL2 can get audio from a program in two ways. With a callback, SDL's audio thread calls your function whenever it needs more samples. With a queue, the program pushes blocks of samples with `SDL_QueueAudio` and SDL plays them in order. Callbacks mean handing a HolyC function pointer to C, which this guide [hasn't tested](runtime-bindings.md#callbacks). The queue avoids that entirely: leave `callback` as `NULL` when opening the device.

```holyc
SdlAudioSpec want;
MemSet(&want, 0, sizeof(SdlAudioSpec));
want.freq = AUDIO_RATE;          // 48000 samples per second
want.format = AUDIO_S16SYS;      // signed 16-bit
want.channels = 1;
want.samples = 1024;

U32 device = SDL_OpenAudioDevice(NULL, 0, &want, NULL, 0);
SDL_PauseAudioDevice(device, 0); // devices open paused
```

Passing `0` for `allowed_changes` tells SDL to convert to whatever the hardware actually uses, so the program can always write 48 kHz mono samples.

`SdlAudioSpec` in `sdl2.HC` mirrors C's `SDL_AudioSpec` field for field. Its fields happen to need no padding, so the layout is the same whether or not a compiler aligns them.

## A square wave

A square wave at `freq` Hz is `freq` full cycles per second, or `2 * freq` half-cycles. Sample `i` falls in half-cycle `i * freq * 2 / AUDIO_RATE`. Even half-cycles are high and odd ones are low:

```holyc
I64 level = a->volume;
if ((i * freq * 2 / AUDIO_RATE) % 2)
  level = 0 - level;
samples[i] = level;
```

It's all integer math, and the volume is out of 32767. The default, 3000, is plenty: square waves are loud.

Jumping straight from silence to full volume, or back, makes a click. `AudioBeep` ramps the level over the first and last 4 ms of each beep.

## Playing sounds from a game

`AudioBeep(&audio, freq, ms)` generates the samples, queues them and returns at once. Calling it from a frame loop doesn't stall the game. A frequency of 0 queues silence, which is how the tune gets its rests.

Sounds play in the order they were queued, so a burst of events queues a backlog that plays late. For effects that should cut off whatever is playing, clear the queue first:

```holyc
SDL_ClearQueuedAudio(audio.device);
AudioBeep(&audio, 988, 60);
AudioBeep(&audio, 1319, 180);
```

`AudioQueuedMs` reports how much sound is still waiting. `AudioWait` blocks until the queue is empty, which only a program like `beep.HC` needs before it exits.

## Without a sound card

CI runners have no audio hardware. SDL's dummy driver accepts and discards the samples at real-time speed, so the program behaves the same way:

```sh
SDL_AUDIODRIVER=dummy ./build/bin/beep
```

To check what the program actually produced, the `disk` driver writes the mixed output to a raw file (16-bit little-endian stereo at 48 kHz, after SDL's conversion). Open it in Audacity with File → Import → Raw Data.

```sh
SDL_AUDIODRIVER=disk SDL_DISKAUDIOFILE=out.raw ./build/bin/beep
```
