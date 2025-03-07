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
    inherit bottom cpufetch duf fastfetch htop ncdu procs;

    # General utilities
    inherit age direnv hyperfine onefetch p7zip pandoc rename taskwarrior3 tealdeer unrar;

    # Media viewers
    inherit chafa;

    # Text editors
    inherit nano neovim;

    # Web
    inherit aria curl oha openssh qrcp wget xh;

    # Development
    inherit dotnet-sdk nodejs openjdk uv;
}
