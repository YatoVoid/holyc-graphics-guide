# Profiling

hcc writes ordinary native executables, so the system profilers work on them. This page uses `simple-3d`, the software renderer, as the program being profiled.

## What a profiler sees

- **Function names.** hcc keeps the symbol table, so samples are attributed to your HolyC functions by name. Your `Main` shows up as `MainFn`, called from a small C `main`.
- **Call stacks.** Every function hcc generates sets up a frame pointer (`push %rbp; mov %rsp,%rbp`), which is what profilers walk to build call graphs. Nothing extra is needed at compile time.
- **No source lines.** hcc emits no debug info, so a profiler can tell you which function is hot, and which instruction, but not which line of HolyC.
- **Nothing from the JIT.** Code run with `hcc -jit` lives in anonymous memory, and a profiler shows it as bare addresses. Build the program with `hcc file.HC -o file` before profiling it.

## perf on Linux

Install it with `sudo apt install linux-tools-common linux-tools-$(uname -r)` on Debian and Ubuntu, `sudo dnf install perf` on Fedora, or `sudo pacman -S perf` on Arch.

```sh
cd examples/simple-3d
hcc cube.HC -o cube
perf record -g --user-callchains -- ./cube     # let it run, then press Esc
perf report --no-children --dso cube
```

`-g` records a call stack with each sample. `--user-callchains` limits those stacks to your program's side. Most distributions set `kernel.perf_event_paranoid` to 2, which forbids kernel stacks to normal users, and without the flag `perf record -g` fails with "Failure to open any events for recording".

`--dso cube` lists only functions in the program itself. Without it the report also includes SDL, libc and the graphics driver, which matters when the time is going there. Percentages are of all samples either way.

On a CPU with both performance and efficiency cores, perf records each core type as a separate event, and the report has a section for each. Read the one with most of the samples.

For a window program in a script or over SSH, SDL's offscreen driver and `timeout` give a fixed-length run with no window:

```sh
SDL_VIDEODRIVER=offscreen perf record -g --user-callchains -- timeout 5 ./cube
```

The report for `cube`, trimmed. Each function is followed by the call stacks it was sampled in, innermost first:

```text
    32.38%  cube     [.] EdgeSide
            |--28.65%--EdgeSide
            |          |--24.51%--CanvasFillTriangle
            |          |          RenderFrame
            |          |          MainFn
            |          |          main
            |           --4.14%--RenderFrame
            |                     MainFn
            |                     main
    23.22%  cube     [.] CanvasFillRect
             --23.21%--CanvasFillRect
                       DrawFloor
                       RenderFrame
                       MainFn
                       main
    22.23%  cube     [.] CanvasFillTriangle
```

A third of the time goes to `EdgeSide`, the one-expression function `CanvasFillTriangle` calls three times per pixel. Almost a quarter goes to `CanvasFillRect`, all of it from `DrawFloor` filling the background. That's the kind of answer a profile is for: which function to work on, and from which caller.

`RenderFrame` never calls `EdgeSide` directly, so the 4% path is wrong. A sample that lands in the first instructions of a function, before it has set up its frame pointer, loses its immediate caller. That's a limit of call graphs built from frame pointers, and it only moves small percentages.

## Reading the hot code

`perf annotate` shows where inside a function the samples land:

```sh
perf annotate --stdio -s EdgeSide
```

Without debug info it's assembly only. To read the assembly of the whole program, ask hcc for it:

```sh
hcc -S cube.HC -o cube.s     # or -o- for stdout
```

Functions keep their HolyC names as labels. `EdgeSide` begins:

```text
EdgeSide:
	pushq   %rbp
	movq    %rsp, %rbp
	subq    $48, %rsp
	movq    %rcx, -8(%rbp)
	movq    %rdx, %rax
	subq    %rdi, %rax
	movq    %rax, -16(%rbp)
```

Two things show up throughout hcc's output:

- **Intermediate values go through memory.** Each step of a calculation is stored to the stack and loaded back for the next one, where an optimizing C compiler would keep them in registers.
- **Nothing is inlined.** A call is always a call. For a function as small as `EdgeSide`, the call is a big part of its cost: 100 million calls took about 420 ms in a test on an x86_64 desktop, against about 215 ms for the same expression written into the loop.

So the changes that pay off with hcc are the ones that do less work in the innermost loop: moving calculations that don't change out of it, writing small helpers into it by hand, and updating values incrementally rather than recomputing them. Measure before and after. Each of these makes the code longer.

## Timing from inside the program

hcc's runtime has `NowMilliseconds()`. To time one part of a frame, add up the elapsed time across many frames and print the average, since a single frame is too short to measure in milliseconds:

```holyc
U64 render_ms = 0;
I64 frames = 0;
// ... then in the frame loop:
U64 start = NowMilliseconds();
RenderFrame(&screen.canvas, t / 1000.0, wireframe);
render_ms += NowMilliseconds() - start;
frames++;
if (frames == 300) {
  "render: %d ms per 100 frames\n", render_ms / 3;
  render_ms = 0;
  frames = 0;
}
```

## Instruments on macOS

The same ideas apply on macOS, through Instruments' **Time Profiler**, either from the Instruments app (choose the built executable as the target) or from the command line:

```sh
xcrun xctrace record --template 'Time Profiler' --launch -- ./cube
open *.trace
```

For a quick text call tree of a running program, `sample cube 5` samples it for five seconds.

The macOS commands above haven't been tested by this guide; only Linux has. Expect function names to show up the same way. Apple's arm64 calling convention requires frame pointers, so call stacks should work too, but check the first profile against what you know the program does.
