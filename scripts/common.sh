# Shared by build-linux.sh and build-macos.sh. Not meant to be run directly.

# The hcc commit every example in this repo was tested against.
HCC_REPO="${HCC_REPO:-https://github.com/Jamesbarford/holyc-lang.git}"
HCC_REF="${HCC_REF:-06ca61140ef143fe83218a33dbc9cf9e2c199509}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/build/bin"

INSTALL_HCC=0
PREFIX="$HOME/.local"
ONLY=""

usage() {
  cat <<EOF
Usage: $(basename "$0") [--install-hcc] [--prefix DIR] [--only NAME]

  --install-hcc   clone and build hcc ($HCC_REF) before building examples
  --prefix DIR    where to install hcc (default: \$HOME/.local)
  --only NAME     build a single example, e.g. --only sprite-demo

Binaries go to build/bin/.
EOF
}

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --install-hcc) INSTALL_HCC=1 ;;
      --prefix) shift; PREFIX="${1:?--prefix needs a directory}" ;;
      --only) shift; ONLY="${1:?--only needs an example name}" ;;
      -h|--help) usage; exit 0 ;;
      *) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
  done
}

need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "missing: $1 ($2)" >&2
    return 1
  fi
}

# Links an empty C program with the given flags: the same check the
# linker will make when hcc hands it the #link libraries.
can_link() {
  echo 'int main(void) { return 0; }' | cc -x c - "$@" -o /dev/null >/dev/null 2>&1
}

install_hcc() {
  need git "install git" || exit 1
  need make "install make" || exit 1
  need cmake "install cmake" || exit 1
  need cc "install gcc or clang" || exit 1

  local src="$ROOT/build/holyc-lang"
  if [ ! -d "$src/.git" ]; then
    git clone "$HCC_REPO" "$src"
  fi
  git -C "$src" fetch --quiet origin
  git -C "$src" checkout --quiet "$HCC_REF"

  mkdir -p "$PREFIX/bin" "$PREFIX/lib" "$PREFIX/include"
  make -C "$src" INSTALL_PREFIX="$PREFIX"
  make -C "$src" install

  case ":$PATH:" in
    *":$PREFIX/bin:"*) ;;
    *) echo "note: add $PREFIX/bin to PATH to use hcc from any shell" ;;
  esac
  export PATH="$PREFIX/bin:$PATH"
}

# build_one <dir> <source> <binary> [extra hcc args...]
build_one() {
  local dir="$1" src="$2" bin="$3"
  shift 3
  if [ -n "$ONLY" ] && [ "$ONLY" != "$dir" ]; then
    return 0
  fi
  printf '  %-14s -> build/bin/%s\n' "$dir" "$bin"
  hcc "$@" "$ROOT/examples/$dir/$src" -o "$OUT/$bin"
}

build_examples() {
  local gl_flags=("$@")
  need hcc "run with --install-hcc, or see docs/build-from-source.md" || exit 1
  mkdir -p "$OUT"
  echo "building with $(hcc --version 2>&1 | head -n 1)"
  build_one hello-world hello.HC hello
  build_one draw-basic draw.HC draw
  build_one sprite-demo sprite.HC sprite
  build_one simple-3d cube.HC cube
  build_one sdl-demo sdl_example.HC sdl_example
  build_one opengl-demo opengl_example.HC opengl_example ${gl_flags[@]+"${gl_flags[@]}"}
  echo "done"
}
