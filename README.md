# Personal dotfiles

This repository contains my personal dotfiles and helper scripts for rule-based templating and age-backed encryption.

I use Nix as a universal package manager on Linux and Homebrew on macOS. Please note that dotfiles in the `src/` directory must be pre-processed before use.

Supported platforms:
- Linux
- macOS (including the arm64 version)

## Installation

This repository can be installed in one line:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/raymond-u/dotfiles/HEAD/install.sh)
```

If you want to perform a dry run before installing, use the --dry-run flag:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/raymond-u/dotfiles/HEAD/install.sh) --dry-run
```

Additional options can be viewed with the following command:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/raymond-u/dotfiles/HEAD/install.sh) --help
```

## License

MIT license.
