#!/usr/bin/env bash
# Builds every example and checks that it actually works:
#   - headless programs must exit 0 and produce the expected output
#   - window programs run for a few seconds on SDL's offscreen driver and
#     must still be running when the timeout stops them (no crash on start)
# Pass --no-gl to skip running the OpenGL demo, which needs a GPU context.
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

build_script="$ROOT/scripts/build-linux.sh"
[ "$(uname -s)" = "Darwin" ] && build_script="$ROOT/scripts/build-macos.sh"
"$build_script" || { echo "build failed"; exit 1; }

echo "checking"

if "$BIN/hello" | grep -q '^Hello from HolyC!$'; then
  pass "hello prints its greeting"
else
  fail "hello prints its greeting"
fi

if (cd "$ROOT/examples/hello-world" && hcc -jit hello.HC) | grep -q 'stands at (6, 5)'; then
  pass "hello runs under the JIT"
else
  fail "hello runs under the JIT"
fi

# "P6\n<w> <h>\n255\n", then w*h RGB triples.
check_ppm() {
  local file="$1" w="$2" h="$3"
  [ -f "$file" ] || return 1
  [ "$(head -c 2 "$file")" = "P6" ] || return 1
  local header_bytes=$((${#w} + ${#h} + 9))
  [ "$(wc -c <"$file" | tr -d ' ')" -eq $((header_bytes + w * h * 3)) ]
}

if "$BIN/draw" "$TMP/draw.ppm" >/dev/null && check_ppm "$TMP/draw.ppm" 320 200; then
  pass "draw writes a 320x200 image"
else
  fail "draw writes a 320x200 image"
fi

if "$BIN/cube" --ppm "$TMP/cube.ppm" >/dev/null && check_ppm "$TMP/cube.ppm" 320 200; then
  pass "cube renders a frame to a file"
else
  fail "cube renders a frame to a file"
fi

# A window program that is still running after 3 seconds started fine.
check_window() {
  local name="$1" dir="$2"
  local status
  (cd "$ROOT/examples/$dir" && SDL_VIDEODRIVER=offscreen timeout 3 "$BIN/$name" >"$TMP/$name.log" 2>&1)
  status=$?
  if [ "$status" -eq 124 ]; then
    pass "$name opens and keeps running"
  else
    fail "$name opens and keeps running (exit $status)"
    sed 's/^/        /' "$TMP/$name.log"
  fi
}

check_window sprite sprite-demo
check_window cube simple-3d
check_window sdl_example sdl-demo
if [ "$RUN_GL" = 1 ]; then
  check_window opengl_example opengl-demo
else
  echo "  skip  opengl_example (--no-gl)"
fi

if [ "$failures" -gt 0 ]; then
  echo "$failures check(s) failed"
  exit 1
fi
echo "all checks passed"
