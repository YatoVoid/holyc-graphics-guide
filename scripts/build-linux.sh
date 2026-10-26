#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/common.sh"
parse_args "$@"

if [ "$INSTALL_HCC" = 1 ]; then
  install_hcc
fi

if ! can_link -lSDL2 -lSDL2_image -lGL; then
  cat >&2 <<'EOF'
warning: cc can't link against SDL2, SDL2_image and OpenGL, so only
hello-world, draw-basic and font-text will build. Install the development
packages:
  Debian/Ubuntu:  sudo apt install libsdl2-dev libsdl2-image-dev libgl-dev
  Fedora:         sudo dnf install SDL2-devel SDL2_image-devel mesa-libGL-devel
  Arch:           sudo pacman -S sdl2-compat sdl2_image mesa
EOF
fi

build_examples
