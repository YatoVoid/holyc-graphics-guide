# Installation

You need three things:

1. **A C toolchain** (`cc`, `make`, `cmake`, `git`). hcc is written in C, and at compile time it calls `cc` to assemble and link your program.
2. **hcc**, built from source. There are no prebuilt packages.
3. **SDL2, SDL2_image and OpenGL development libraries**, for the window examples and image loading. `hello-world`, `draw-basic` and `font-text` work without them.

## 1. Dependencies

=== "Debian / Ubuntu"

    ```sh
    sudo apt install build-essential cmake git libsdl2-dev libsdl2-image-dev libgl-dev
    ```

=== "Fedora"

    ```sh
    sudo dnf install gcc make cmake git SDL2-devel SDL2_image-devel mesa-libGL-devel
    ```

=== "Arch"

    ```sh
    sudo pacman -S base-devel cmake git sdl2-compat sdl2_image mesa
    ```

    On current Arch, `sdl2-compat` provides the SDL2 API on top of SDL3. The examples work with it unchanged.

=== "macOS"

    ```sh
    xcode-select --install
    brew install cmake sdl2 sdl2_image
    ```

    OpenGL ships with macOS as a framework, so there's nothing to install for it. Apple deprecated OpenGL in 2018 but still includes 4.1 core, which is enough for everything here.

=== "Windows (WSL2)"

    In an admin PowerShell:

    ```powershell
    wsl --install -d Ubuntu
    ```

    Reboot, open the Ubuntu shell, and follow the Debian/Ubuntu tab. Windows 11 and recent Windows 10 builds include WSLg, which displays Linux GUI windows on your desktop. Run `glxinfo -B` inside WSL (`sudo apt install mesa-utils`) to check that OpenGL works.

## 2. hcc

The build scripts can clone, build and install hcc for you. By default it goes into `~/.local`, so you don't need root:

```sh
git clone https://github.com/YatoVoid/holyc-graphics-guide.git
cd holyc-graphics-guide
./scripts/build-linux.sh --install-hcc     # or build-macos.sh
```

This pins hcc to the commit the examples were tested against. Make sure `~/.local/bin` is on your `PATH`:

```sh
export PATH="$HOME/.local/bin:$PATH"   # add to ~/.bashrc or ~/.zshrc
hcc --version
```

To build hcc by hand, or to understand what the script does, see [Build hcc from source](build-from-source.md).

## 3. Check everything

```sh
./scripts/check.sh
```

This builds all thirteen examples, checks the output of the ones that don't need a window, and starts each window program for three seconds to make sure it doesn't crash. Add `--no-gl` on machines without a working OpenGL driver.

Next: [Quick start](quickstart.md).
