#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"
parse_args "$@"

if ! xcode-select -p >/dev/null 2>&1; then
  echo "missing: Xcode command line tools (run: xcode-select --install)" >&2
  exit 1
fi

if [ "$INSTALL_HCC" = 1 ]; then
  install_hcc
fi

brew_lib="$(brew --prefix 2>/dev/null || echo /opt/homebrew)/lib"
if ! can_link -L"$brew_lib" -lSDL2 -lSDL2_image; then
  echo "warning: cc can't link against SDL2 and SDL2_image (brew install sdl2 sdl2_image). Only hello-world, draw-basic and font-text will build." >&2
fi

# OpenGL lives in a framework on macOS, which #link can't express.
build_examples -clibs "-framework OpenGL"
