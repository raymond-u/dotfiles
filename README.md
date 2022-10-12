# My personal dotfiles

This repo contains my personal dotfiles, and helper scripts that allow rule-based templating and age-backed encryption.

Note that I use Homebrew on macOS and Nix as a universal package manager on Linux. Language-specific package managers can be installed independently.

Supported platforms:
- macOS (including arm64 version)
- Linux

## Installation

This repo can be installed in one line:

```bash
$ bash -c "$(curl -fsSL https://raw.githubusercontent.com/raymond-u/dotfiles/HEAD/install.sh)"
```

If you want to have a dry run:

```bash
$ bash -c "$(curl -fsSL https://raw.githubusercontent.com/raymond-u/dotfiles/HEAD/install.sh)" -s --dry-run
```

More options can be viewed with:

```bash
$ bash -c "$(curl -fsSL https://raw.githubusercontent.com/raymond-u/dotfiles/HEAD/install.sh)" -s --help
```

## License

MIT license.
