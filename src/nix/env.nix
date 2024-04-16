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
    inherit bat eza fd fzf hexyl ripgrep sd tree zoxide;

    # System utilities
    inherit bottom duf htop ncdu neofetch procs;

    # General utilities
    inherit age direnv hyperfine p7zip pandoc rename taskwarrior tealdeer unrar;

    # Media viewers
    inherit chafa;

    # Text editors
    inherit nano neovim;

    # Web
    inherit aria curl openssh qrcp wget xh;

    # Development
    inherit corepack dotnet-sdk nodejs openjdk pipx;
}
