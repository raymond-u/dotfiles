# Set general envs
export XDG_CACHE_HOME="${HOME}/.cache"
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_STATE_HOME="${HOME}/.local/state"

# [ is_linux start ]
# Make wezterm connect happy
export PATH="${HOME}/bin:${HOME}/.nix-profile/bin${PATH:+:${PATH}}"
# [ is_linux end ]

# [ is_macos_arm64 start ]
# Initialize homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"
# [ is_macos_arm64 end ]

# [ is_macos start ]
# Configure .NET
export DOTNET_ROOT="$(brew --prefix)/opt/dotnet/libexec"
# [ is_macos end ]

# [ is_macos start ]
# Configure Java
export JAVA_HOME="$(brew --prefix)/opt/openjdk"
# [ is_macos end ]
