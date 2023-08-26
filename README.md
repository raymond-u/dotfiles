# Dotfiles

This is my personal dotfiles repository. This collection includes my custom dotfiles and helper scripts designed to provide a simple yet powerful templating and encryption system for dotfiles.

## Features

- **Automated OS and Architecture Detection:** The script can identify the operating system and architecture of your machine automatically, ensuring a seamless setup experience.
- **Versatile Package Management:** Depending on your OS, the script will utilize Nix (for Linux) or Homebrew (for macOS) for package management, providing you with a consistent and streamlined user experience.
- **Comprehensive Zsh Configuration:** The repository contains a robust Zsh configuration that is feature-packed and ready for use.
- **Handy Aliases and Functions:** The dotfiles contain my personal selection of aliases and functions, designed to increase productivity and simplify common tasks.
- **Ready-to-Use Development Environment:** The setup enables a plug'n'play development environment, saving you the hassle of manual configuration.
- **Self-Updating:** The script is capable of updating itself, ensuring you have the latest features and improvements.

## Compatibility

This repository supports the following platforms:

- Linux
- macOS (Compatible with both Intel-based and Apple Silicon machines)

## Installation

You can install the dotfiles with a single command:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/raymond-u/dotfiles/HEAD/install.sh)
```

If you prefer to perform a dry run before the actual installation, you can use the `--dry-run` flag:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/raymond-u/dotfiles/HEAD/install.sh) --dry-run
```

Additionally, you can view other available options using the `--help` command:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/raymond-u/dotfiles/HEAD/install.sh) --help
```

## License

This repository is licensed under the MIT License.
