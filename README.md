# My personal dotfiles

This repo contains my personal dotfiles, and helper scripts that allow rule-based templating and age-backed encryption.

I use Homebrew on macOS and Nix as a universal package manager on Linux. Language-specific package managers can be installed independently. Note that dotfiles in `src/` must be pre-processed before use.

Supported platforms:
- macOS (including arm64 version)
- Linux

## Installation

This repo can be installed in one line:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/raymond-u/dotfiles/HEAD/install.sh)
```

If you want to have a dry run:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/raymond-u/dotfiles/HEAD/install.sh) --dry-run
```

More options can be viewed with:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/raymond-u/dotfiles/HEAD/install.sh) --help
```

## License

MIT license.
