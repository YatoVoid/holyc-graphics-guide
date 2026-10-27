# Contributing

Bug reports, fixes, docs corrections and new examples are all welcome. For anything large, like a new example or a new docs page, open an issue first so we can agree on the scope.

## Setup

Follow [Installation](https://yatovoid.github.io/holyc-graphics-guide/installation/). The build scripts build the hcc commit pinned in `scripts/common.sh`, which is the one everything is tested against.

## Before opening a pull request

```sh
./scripts/check.sh            # add --no-gl if you have no OpenGL 3.3 driver
```

Every check must pass. It builds every example, compares each `--ppm` frame and `beep`'s samples with `scripts/checksums.txt`, and starts each window program for three seconds.

If you changed what an example draws on purpose, `check.sh` prints the new hash. Look at the new image first, then put that hash in `scripts/checksums.txt`. The OpenGL frames are only compared on Mesa's llvmpipe; on other drivers that check prints `skip`.

For docs changes:

```sh
pip install -r requirements-docs.txt
mkdocs build --strict
```

## Writing examples

- Match the style of the existing examples: plain HolyC, an `I32 Main` entry point, shared code from `examples/common/`, no C or C++.
- If it draws, give it a `--ppm <file>` mode that renders a fixed frame without a window, and add a check for it to `scripts/check.sh`.
- Read [Compiler quirks](https://yatovoid.github.io/holyc-graphics-guide/compiler-quirks/) first. If code compiles but gives wrong results, it's often one of those.

## Reporting hcc bugs

If you find a compiler bug, cut it down to the smallest program that shows it and check whether it also happens under `hcc -jit`. Report it [upstream](https://github.com/Jamesbarford/holyc-lang/issues). Open an issue here too if the guide should list it with a workaround.
