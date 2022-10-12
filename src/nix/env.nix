let pkgs = import <nixpkgs> {};
in with pkgs;
{
    # Shells
    inherit bash zsh;
    
    # Terminal multiplexer
    inherit wezterm;
    
    # System commands
    inherit coreutils gawk gnused less;
    
    # General commands
    inherit bat exa fd fzf ripgrep zoxide;
    
    # System utilities
    inherit duf htop ncdu neofetch procs thefuck tldr tree;
    
    # General utilities
    inherit age pandoc rename;
    
    # Text editors
    inherit nano neovim vim;
    
    # Web
    inherit aria curl httpie openssh qrcp wget;
}
