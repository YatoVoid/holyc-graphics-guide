# Build hcc from source

`scripts/build-linux.sh --install-hcc` does all of this for you. This page covers the same steps by hand, plus the options you might want to change.

## Requirements

- Linux or macOS, on x86_64 or AArch64 (Windows: inside WSL2)
- A C compiler (`gcc` or `clang`), `make`, `cmake`, `git`

## Clone

```sh
git clone https://github.com/Jamesbarford/holyc-lang.git
cd holyc-lang
```

hcc changes quickly, and it's beta software. To get exactly the version these examples were tested against:

```sh
git checkout 06ca61140ef143fe83218a33dbc9cf9e2c199509
```

The latest `master` will probably work too. If it doesn't, check [Compiler quirks](compiler-quirks.md) and the upstream issue tracker before assuming your code is wrong.

## Build and install

The top-level `Makefile` wraps CMake. It installs to `/usr/local` unless you set `INSTALL_PREFIX`:

=== "Into ~/.local (no root)"

    ```sh
    mkdir -p ~/.local/bin ~/.local/lib ~/.local/include
    make INSTALL_PREFIX="$HOME/.local"
    make install
    ```

=== "System-wide"

    ```sh
    make
    sudo make install
    ```

`make install` puts three things under the prefix:

| Path | What it is |
|---|---|
| `bin/hcc` | the compiler |
| `lib/libtos.a`, `lib/libtos.so*` | the HolyC runtime library (strings, memory, files, hash tables, `printf`) |
| `include/tos.HH` | declarations for that library, included into every program automatically |

The prefix is compiled into hcc, which is how it finds `tos.HH` and `libtos` later. If you move them, either rebuild hcc or pass `--install-dir=<prefix>` on every compile.

!!! warning "Create the lib directory first"
    If `<prefix>/lib` doesn't exist, `make install` fails partway through. That's why the first command above creates it.

## Build options

| Option | Default | Effect |
|---|---|---|
| `INSTALL_PREFIX` | `/usr/local` | where `make install` puts things |
| `C_COMPILER` | `gcc` | compiler used to build hcc itself |
| `BUILD_TYPE` | `Release` | CMake build type; `Debug` to debug hcc |
| `-DHCC_LINK_SQLITE3=1` | off | adds SQLite bindings to the runtime; edit the `Makefile` to pass it |

The JIT (`hcc -jit`) and the REPL (`hcc -repl`) are enabled by the default Makefile build.

## Run hcc's own tests

```sh
make unit-test
```

## Environment

hcc doesn't read any environment variables you need to set. Two things matter:

- **`PATH`** must include `<prefix>/bin` so your shell finds `hcc`.
- **`cc`** must be on `PATH` at compile time. hcc calls it to assemble and link. Programs built with hcc don't need hcc or `libtos` at runtime, because `libtos` is linked statically. They only need the shared C libraries they `#link` (SDL2, SDL2_image, GL).

## Updating

```sh
cd holyc-lang
git pull
make INSTALL_PREFIX="$HOME/.local" && make install
```

Then rerun `./scripts/check.sh` in this repo to see if anything broke.
