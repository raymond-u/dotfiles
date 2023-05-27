# Set general envs
export XDG_CACHE_HOME="${HOME}/.cache"
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_STATE_HOME="${HOME}/.local/state"

# [ is_linux start ]
# Make wezterm connect happy
export PATH="${HOME}/bin:${HOME}/.nix-profile/bin${PATH:+:${PATH}}"

# Ensure shell integration is hookup up only once
export WEZTERM_SHELL_SKIP_ALL=1
# [ is_linux end ]

# [ is_macos start ]
# [ is_macos_arm64 start ]
# Configure .NET
export DOTNET_ROOT="$(/opt/homebrew/bin/brew --prefix)/opt/dotnet/libexec"

# Configure Java
export JAVA_HOME="$(/opt/homebrew/bin/brew --prefix)/opt/openjdk"
# [ is_macos_arm64 end ]
# [ ! is_macos_arm64 start ]
# Configure .NET
export DOTNET_ROOT="$(brew --prefix)/opt/dotnet/libexec"

# Configure Java
export JAVA_HOME="$(brew --prefix)/opt/openjdk"
# [ ! is_macos_arm64 end ]
# [ is_macos end ]
