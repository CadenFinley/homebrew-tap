# CadenFinley Homebrew Tap

This tap hosts the Homebrew formulas for [CJSH](https://github.com/CadenFinley/CJsShell), a POSIX-focused shell with modern conveniences. It includes the stable release and a development build that tracks arbitrary branches.

## Prerequisites

- Homebrew installed on macOS or Linux.
- `cmake` is pulled in automatically by the formulas as a build dependency.

## Installation

Tap the repository once and install whichever formula you need:

```bash
brew tap cadenfinley/homebrew-tap
brew install cadenfinley/homebrew-tap/cjsh      # stable release
brew install cadenfinley/homebrew-tap/cjsh-dev  # development builds
```

### `cjsh`

- Builds from the `4.2.0` tagged release (revision `72071e8`).
- Suitable for day-to-day use when you want the latest stable shell.

Example usage after installation:

```bash
cjsh --version
cjsh -c 'echo hello from cjsh'
```

### `cjsh-dev`

- Tracks the head of a branch in the upstream `CadenFinley/CJsShell` repo.
- Defaults to the `master` branch but can follow any other branch for testing upcoming changes.

Install the default development build:

```bash
brew install cadenfinley/homebrew-tap/cjsh-dev
```

Install from a different development branch by setting `CJSH_DEV_BRANCH` before running Homebrew. Example for the `feature-repl` branch:

```bash
CJSH_DEV_BRANCH=feature-repl brew install cadenfinley/homebrew-tap/cjsh-dev
```

Once installed, verify the build and run commands just like the stable release:

```bash
cjsh --version
cjsh -c 'echo testing dev build'
```

## Updating

Use `brew upgrade cadenfinley/homebrew-tap/cjsh` (or `cjsh-dev`) to build the latest version available for the selected track. For development builds, re-run the install command with the desired `CJSH_DEV_BRANCH` whenever you need to switch branches.
