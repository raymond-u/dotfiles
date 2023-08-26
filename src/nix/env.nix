let pkgs = import <nixpkgs> {};
in with pkgs;
{
    # Shells
    inherit bash zsh;

    # Terminal
    inherit wezterm;

    # System commands
    inherit coreutils findutils gawk gnused less;

    # General commands
    inherit bat exa fd fzf hexyl ripgrep tree zoxide;

    # System utilities
    inherit bottom duf htop ncdu neofetch procs;

    # General utilities
    inherit age direnv hyperfine p7zip pandoc rename taskwarrior tealdeer thefuck unrar;

    # Media viewers
    inherit chafa;

    # Text editors
    inherit nano neovim vim;

    # Web
    inherit aria curl httpie openssh qrcp wget;

    # Development
    inherit poetry;
}
