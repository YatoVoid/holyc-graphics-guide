#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"
parse_args "$@"

if [ "$INSTALL_HCC" = 1 ]; then
  install_hcc
fi

if ! can_link -lSDL2 -lGL; then
  cat >&2 <<'EOF'
warning: cc can't link against SDL2 and OpenGL, so only hello-world and
draw-basic will build. Install the development packages:
  Debian/Ubuntu:  sudo apt install libsdl2-dev libgl-dev
  Fedora:         sudo dnf install SDL2-devel mesa-libGL-devel
  Arch:           sudo pacman -S sdl2-compat mesa
EOF
fi

build_examples
