#!/usr/bin/env bash
# Builds every example and checks that it actually works:
#   - headless programs must exit 0 and produce the expected output
#   - window programs run for a few seconds on SDL's offscreen driver and
#     must still be running when the timeout stops them (no crash on start)
# Pass --no-gl to skip running the OpenGL programs, which need an OpenGL 3.3
# context from a GPU driver or Mesa's llvmpipe.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$ROOT/build/bin"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

RUN_GL=1
[ "${1:-}" = "--no-gl" ] && RUN_GL=0

failures=0
pass() { printf '  ok    %s\n' "$1"; }
fail() { printf '  FAIL  %s\n' "$1"; failures=$((failures + 1)); }

# run_for SECONDS COMMAND...: like GNU timeout, including exit status 124
# when the time runs out. macOS has no timeout unless coreutils is
# installed (as gtimeout), so fall back to a background watcher.
run_for() {
  local secs="$1"
  shift
  if command -v timeout >/dev/null 2>&1; then
    timeout "$secs" "$@"
    return
  fi
  if command -v gtimeout >/dev/null 2>&1; then
    gtimeout "$secs" "$@"
    return
  fi
  "$@" &
  local pid=$!
  (sleep "$secs" && touch "$TMP/timed-out.$pid" && kill -TERM "$pid" 2>/dev/null) &
  local watcher=$!
  wait "$pid"
  local status=$?
  kill "$watcher" 2>/dev/null
  wait "$watcher" 2>/dev/null
  if [ -e "$TMP/timed-out.$pid" ]; then
    rm -f "$TMP/timed-out.$pid"
    return 124
  fi
  return "$status"
}

build_script="$ROOT/scripts/build-linux.sh"
[ "$(uname -s)" = "Darwin" ] && build_script="$ROOT/scripts/build-macos.sh"
"$build_script" || { echo "build failed"; exit 1; }

echo "checking"

# Headless programs finish in well under a second; the limit turns a hang
# into one failed check instead of a stuck job.
if run_for 30 "$BIN/hello" | grep -q '^Hello from HolyC!$'; then
  pass "hello prints its greeting"
else
  fail "hello prints its greeting"
fi

if (cd "$ROOT/examples/hello-world" && run_for 30 hcc -jit hello.HC) | grep -q 'stands at (6, 5)'; then
  pass "hello runs under the JIT"
else
  fail "hello runs under the JIT"
fi

sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d ' ' -f 1
  else
    shasum -a 256 "$1" | cut -d ' ' -f 1
  fi
}

# "P6\n<w> <h>\n255\n", then w*h RGB triples, and the same pixels as the
# image recorded in scripts/checksums.txt. After an intended change to
# what an example draws, look at the new image, then put the printed hash
# in checksums.txt.
check_ppm() {
  local file="$1" w="$2" h="$3"
  [ -f "$file" ] || return 1
  [ "$(head -c 2 "$file")" = "P6" ] || return 1
  local header_bytes=$((${#w} + ${#h} + 9))
  [ "$(wc -c <"$file" | tr -d ' ')" -eq $((header_bytes + w * h * 3)) ] || return 1
  local name expected actual
  name="$(basename "$file")"
  expected="$(awk -v n="$name" '$2 == n { print $1 }' "$ROOT/scripts/checksums.txt")"
  actual="$(sha256 "$file")"
  if [ "$actual" != "$expected" ]; then
    echo "        $name: sha256 $actual, expected ${expected:-nothing}"
    return 1
  fi
}

if run_for 30 "$BIN/draw" "$TMP/draw.ppm" >/dev/null && check_ppm "$TMP/draw.ppm" 320 200; then
  pass "draw draws the expected 320x200 image"
else
  fail "draw draws the expected 320x200 image"
fi

if run_for 30 "$BIN/text" "$TMP/text.ppm" >/dev/null && check_ppm "$TMP/text.ppm" 320 200; then
  pass "text draws the expected 320x200 image"
else
  fail "text draws the expected 320x200 image"
fi

if (cd "$ROOT/examples/image-load" && run_for 30 "$BIN/load" "$TMP/load.ppm" >/dev/null) && check_ppm "$TMP/load.ppm" 240 160; then
  pass "load draws a PPM and a PNG as expected"
else
  fail "load draws a PPM and a PNG as expected"
fi

if run_for 30 "$BIN/tilemap" --ppm "$TMP/tilemap.ppm" >/dev/null && check_ppm "$TMP/tilemap.ppm" 240 160; then
  pass "tilemap plays two seconds to the expected frame"
else
  fail "tilemap plays two seconds to the expected frame"
fi

if run_for 30 "$BIN/bounce" --ppm "$TMP/bounce.ppm" >/dev/null && check_ppm "$TMP/bounce.ppm" 640 480; then
  pass "bounce runs 20000 steps to the expected image"
else
  fail "bounce runs 20000 steps to the expected image"
fi

if run_for 30 "$BIN/cube" --ppm "$TMP/cube.ppm" >/dev/null && check_ppm "$TMP/cube.ppm" 320 200; then
  pass "cube renders the expected frame"
else
  fail "cube renders the expected frame"
fi

if run_for 30 "$BIN/pad" --ppm "$TMP/pad.ppm" | grep -q '^unplugged and found again$' && check_ppm "$TMP/pad.ppm" 240 160; then
  pass "pad draws a virtual controller and sees it unplugged"
else
  fail "pad draws a virtual controller and sees it unplugged"
fi

# SDL's disk driver plays the queue at real-time speed into a raw file.
# The file isn't the same from one SDL to the next: SDL2 writes the mono
# stream beep asked for, SDL3's sdl2-compat writes stereo with both
# channels the same and logs its format, and how much silence comes
# before and after the sound depends on timing. So keep one channel, drop
# the silence at both ends, and hash the samples as text.
check_audio() {
  local raw="$1" log="$2" channels format
  [ -s "$raw" ] || return 1
  channels="$(sed -n 's/.*channels=\([0-9]*\).*/\1/p' "$log" | head -n 1)"
  format="$(sed -n 's/.*format=\([A-Z0-9]*\).*/\1/p' "$log" | head -n 1)"
  if [ -n "$format" ] && [ "$format" != "S16LE" ]; then
    echo "        beep: disk driver wrote $format, only S16LE is handled"
    return 1
  fi
  od -An -v -t d2 "$raw" | awk -v ch="${channels:-1}" '
    { for (i = 1; i <= NF; i++) { c = n % ch; n++
        if (c == 0) s = $i
        else if ($i != s) { print "channels differ" > "/dev/stderr"; exit 1 }
        if (c == ch - 1) { v[m++] = s } } }
    END { a = 0; b = m - 1
          while (a < m && v[a] == 0) a++
          while (b >= a && v[b] == 0) b--
          for (i = a; i <= b; i++) print v[i] }' >"$TMP/beep.pcm" || return 1
  local expected actual
  expected="$(awk '$2 == "beep.pcm" { print $1 }' "$ROOT/scripts/checksums.txt")"
  actual="$(sha256 "$TMP/beep.pcm")"
  if [ "$actual" != "$expected" ]; then
    echo "        beep.pcm: sha256 $actual, expected ${expected:-nothing}"
    return 1
  fi
}

if SDL_AUDIODRIVER=disk SDL_DISKAUDIOFILE="$TMP/beep.raw" run_for 10 "$BIN/beep" 2>"$TMP/beep.log" | grep -q '^done$' &&
  check_audio "$TMP/beep.raw" "$TMP/beep.log"; then
  pass "beep plays the expected samples and exits"
else
  fail "beep plays the expected samples and exits"
fi

# A window program that is still running after 3 seconds started fine.
# On macOS, SDL makes every window an OpenGL window, and the offscreen
# driver can only get OpenGL through EGL, which macOS doesn't have. The
# dummy driver has no OpenGL, so its windows work there.
video_driver=offscreen
[ "$(uname -s)" = "Darwin" ] && video_driver=dummy
check_window() {
  local name="$1" dir="$2"
  local status
  (cd "$ROOT/examples/$dir" && SDL_VIDEODRIVER="$video_driver" run_for 3 "$BIN/$name" >"$TMP/$name.log" 2>&1)
  status=$?
  if [ "$status" -eq 124 ]; then
    pass "$name opens and keeps running"
  else
    fail "$name opens and keeps running (exit $status)"
    sed 's/^/        /' "$TMP/$name.log"
  fi
}

check_window sprite sprite-demo
check_window tilemap tilemap
check_window pad gamepad
check_window bounce templeos-bounce
check_window cube simple-3d
check_window sdl_example sdl-demo
if [ "$RUN_GL" = 1 ]; then
  check_window opengl_example opengl-demo
  check_window texture gl-texture
else
  echo "  skip  opengl_example, texture (--no-gl)"
fi

if [ "$failures" -gt 0 ]; then
  echo "$failures check(s) failed"
  exit 1
fi
echo "all checks passed"
