# [ use_chroot start ]
# Mount nix if needed
if [[ -z "${_NIX_USER_CHROOT_MOUNTED}" ]]; then
    _NIX_USER_CHROOT_MOUNTED=1 "${HOME}/bin/nix-user-chroot" "${HOME}/.nix" zsh -l
    exit
else
    source "${HOME}/.nix-profile/etc/profile.d/nix.sh"
fi
# [ use_chroot end ]

# Enable Powerlevel10k instant prompt
if [[ -r "${HOME}/.cache/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${HOME}/.cache/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Use emacs key bindings
bindkey -e

# Set zsh options
setopt APPEND_HISTORY         # Append to history instead of replacing it
setopt AUTO_CONTINUE          # Disowned jobs are automatically resumed
setopt COMBINING_CHARS        # Display combining characters correctly
setopt GLOB_DOTS              # Show hidden files in the completion list
setopt HIST_EXPIRE_DUPS_FIRST # Remove duplicates first when trimming history
setopt HIST_FIND_NO_DUPS      # Don't display duplicates when searching
setopt HIST_IGNORE_SPACE      # Don't record lines starting with a space
setopt HIST_REDUCE_BLANKS     # Remove superfluous blanks before recording
setopt HIST_SAVE_NO_DUPS      # Don't write duplicates in the history file
setopt INTERACTIVE_COMMENTS   # Allow comments in interactive shells
setopt LIST_ROWS_FIRST        # Lay out the completion list horizontally
setopt MULTIOS                # Cast multiple redirections to tees or cats implicitly
setopt NO_FLOWCONTROL         # Disable flow control key bindings
setopt PROMPT_SUBST           # Enable parameter expansion, command substitution and arithmetic expansion
setopt RC_QUOTES              # Use two single quotes to signify a single quote within singly quoted strings
setopt SHORT_LOOPS            # Allow the short forms of for, repeat, select, if, and function constructs

# Better case-sensitive handling
zstyle ':completion:*'                                                    matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# Use menu
zstyle ':completion:*'                                                    menu yes=long select

# List directories first
zstyle ':completion:*'                                                    list-dirs-first true

# Set descriptions format to enable group support
zstyle ':completion:*:descriptions'                                       format '[%d]'

# Do not treat // as /*/
zstyle ':completion:*'                                                    squeeze-slashes true

# Speed up path completion
zstyle ':completion:*'                                                    use-cache on
zstyle ':completion:*'                                                    cache-path "${HOME}/.cache/zsh"

# Partial completion suggestions
zstyle ':completion:*'                                                    list-suffixes
zstyle ':completion:*'                                                    expand prefix suffix

# Fuzzy match mistyped completions
zstyle ':completion:*'                                                    completer _complete _list _match _approximate
zstyle ':completion:*:match:*'                                            original only
zstyle ':completion:*:approximate:*'                                      max-errors 1
zstyle ':completion:*:corrections'                                        format ' %F{green}-- %d (errors: %e) --%f'

# Don't complete unavailable commands
zstyle ':completion:*:functions'                                          ignored-patterns '(_*|pre(cmd|exec))'

# Array completion element sorting
zstyle ':completion:*:*:-subscript-:*'                                    tag-order indexes parameters

# Manuals
zstyle ':completion:*:manuals'                                            separate-sections true
zstyle ':completion:*:manuals.(^1*)'                                      insert-sections true

# Kill
zstyle ':completion:*:*:*:*:processes'                                    command 'ps ax -o pid,user,comm -w -w'
zstyle ':completion:*:*:kill:*:processes'                                 list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*:*:kill:*'                                           force-list always
zstyle ':completion:*:*:kill:*'                                           insert-ids single

# Hosts
zstyle ':completion:*:(scp|rsync):*'                                      tag-order 'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address *'
zstyle ':completion:*:(scp|rsync):*'                                      group-order users files all-files hosts-domain hosts-host hosts-ipaddr
zstyle ':completion:*:ssh:*'                                              tag-order users 'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address *'
zstyle ':completion:*:ssh:*'                                              group-order hosts-domain hosts-host users hosts-ipaddr
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host'                       ignored-patterns '*(.|:)*' loopback ip6-loopback localhost ip6-localhost broadcasthost
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-domain'                     ignored-patterns '<->.<->.<->.<->' '^[-[:alnum:]]##(.[-[:alnum:]]##)##' '*@*'
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-ipaddr'                     ignored-patterns '^(<->.<->.<->.<->|(|::)([[:xdigit:].]##:(#c,2))##(|%*))' '127.0.0.<->' '255.255.255.255' '::1' 'fe80::*'

# Fzf-tab
zstyle ':fzf-tab:*'                                                       prefix ''
zstyle ':fzf-tab:*'                                                       fzf-bindings 'space:toggle' 'tab:accept' 'enter:accept' 'right-click:' 'backward-eof:abort'
zstyle ':fzf-tab:*'                                                       switch-group ';' "'"
zstyle ':fzf-tab:*'                                                       single-group color

# Fzf-tab preview
zstyle ':fzf-tab:complete:*'                                              fzf-flags --preview-window=wrap
zstyle ':fzf-tab:complete:(z|cp|mv|rm|exa|bat):argument-rest'             fzf-preview '[[ -d "${realpath}" ]] && exa -1 --icons --group-directories-first "${realpath}" || bat --color always --style grid,numbers -r :200 "${realpath}"'
zstyle ':fzf-tab:complete:(-parameter-|-brace-parameter-|export|unset):*' fzf-preview 'echo "${(P)word}"'
# [ is_linux start ]
zstyle ':fzf-tab:complete:systemctl-*:*'                                  fzf-preview 'SYSTEMD_COLORS=1 systemctl status "${word}"'
# [ is_linux end ]
# [ is_macos start ]
zstyle ':fzf-tab:complete:brew-(install|uninstall|search|info):*'         fzf-preview 'brew info "${word}"'
# [ is_macos end ]

# [ is_macos_arm64 start ]
# Initialize homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"
# [ is_macos_arm64 end ]

# Set general envs
export EDITOR='nvim'
export VISUAL='nvim'
# [ is_linux start ]
export PATH="${HOME}/bin${PATH:+:${PATH}}"
# [ is_linux end ]
# [ is_macos start ]
export PATH="${HOME}/.local/bin\
    :$(brew --prefix)/opt/coreutils/libexec/gnubin\
    :$(brew --prefix)/opt/findutils/libexec/gnubin\
    :$(brew --prefix)/opt/gawk/libexec/gnubin\
    :$(brew --prefix)/opt/gnu-getopt/bin\
    :$(brew --prefix)/opt/gnu-sed/libexec/gnubin\
    ${PATH:+:${PATH}}"
# [ is_macos end ]

# Configure shell history
export HISTSIZE=10000
export SAVEHIST=10000
export HISTFILE="${HOME}/.local/state/zsh/history"

# [ is_linux start ]
# Configure completions for Nix packages
for profile in ''${(z)NIX_PROFILES}; do
    fpath+=(
        "${profile}/share/zsh/site-functions"
        "${profile}/share/zsh/${ZSH_VERSION}/functions"
        "${profile}/share/zsh/vendor-completions"
    )
done
# [ is_linux end ]
# [ is_macos_arm64 start ]
# Configure completions for Homebrew packages
fpath+=("$(brew --prefix)/share/zsh/site-functions")
# [ is_macos_arm64 end ]

# Configure fzf
export FZF_DEFAULT_OPTS='--bind space:toggle,tab:accept,enter:accept,ctrl-a:toggle-all,right-click:,backward-eof:abort'

# [ use_mirror start ]
# [ is_macos start ]
# Configure Homebrew
export HOMEBREW_BREW_GIT_REMOTE=https://mirrors.ustc.edu.cn/brew.git
export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.ustc.edu.cn/homebrew-bottles
# [ is_macos end ]
# [ use_mirror end ]

# Configure less
export LESS='-R -i --wheel-lines=3'
export LESSHISTFILE="${HOME}/.local/state/less/history"

# Configure man
export MANPAGER='sh -c "col -bx | bat -l man -p --pager \"less -R --mouse\""'
export MANROFFOPT='-c'

# Configure taskwarrior
export TASKRC="${HOME}/.config/task/taskrc"

# Configure wget
export WGETRC="${HOME}/.config/wget/wgetrc"

# [ is_linux start ]
# Add missing locale for nix packages
# Uncomment this if locale of nix packages is broken
# export LOCALE_ARCHIVE_2_11="$(nix-build --no-out-link '<nixpkgs>' -A glibcLocales)/lib/locale/locale-archive"
# export LOCALE_ARCHIVE_2_27="$(nix-build --no-out-link '<nixpkgs>' -A glibcLocales)/lib/locale/locale-archive"
# export LOCALE_ARCHIVE=/usr/bin/locale
# [ is_linux end ]

# Aliases for system commands
alias c='cat'
alias cat='bat --pager "less -RXFe"'
alias d='wget'
alias e='nvim'
alias fd='fd -HI'
alias grep='rg'
alias l='ls'
alias la='ls -la'
alias ll='ls -laF'
alias ls='exa --icons --group-directories-first'
alias lsd='exa -D --icons'
alias le='less'
alias less='bat --pager "less -R --mouse" --color always --style grid,numbers'
alias mkdir='mkdir -p'
alias p='chafa --format sixels'
alias quit='exit'
alias rl='readlink -f'
alias rp='realpath'
alias xxd='hexyl'

# Aliases for user commands
# [ is_linux start ]
alias conac='conda activate'
alias conde='conda deactivate'
alias conls='conda env list'
alias concr='conda create -n'
alias conre='conda remove -n'
alias conin='mamba install'
alias conun='mamba remove'
# [ is_linux end ]
alias ginit='git init && gi >.gitignore'
alias gc='git commit -m'
alias gp='git push origin'
# [ has_identity start ]
alias pass='passage'
# [ has_identity end ]

# Functions as aliases
alias bashrc='nvim "${HOME}/.bashrc"'
alias zshrc='nvim "${HOME}/.zshrc"'
alias nohis='unset HISTFILE'
# [ can_sudo start ]
alias reload='echo; exec sudo -i -u "${USER}" bash -c "cd \"${PWD}\"; exec \"${SHELL}\" -l"'
# [ can_sudo end ]
# [ ! can_sudo start ]
alias reload='echo; exec "${SHELL}" -l'
# [ ! can_sudo end ]
alias lanip='ifconfig | sed -En "s/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p"'
alias pubip='curl ipinfo.io/ip; echo'
# [ is_macos start ]
alias hosts='nvim /private/etc/hosts'
alias fix='sudo xattr -d com.apple.quarantine'
alias fixx='sudo xattr -c'
alias flushdns='sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder'
alias mac='ifconfig en0 | rg ether'
# [ is_macos_arm64 start ]
alias macrand='openssl rand -hex 6 | sed "s/\(..\)/\1:/g; s/.$//" | xargs sudo ifconfig en0 lladdr'
# [ is_macos_arm64 end ]
# [ ! is_macos_arm64 start ]
alias macrand='openssl rand -hex 6 | sed "s/\(..\)/\1:/g; s/.$//" | xargs sudo ifconfig en0 ether'
# [ ! is_macos_arm64 end ]
alias pip='pip3'
alias python='python3'
# [ is_macos end ]

# Functions
home-env() {
    local version
    local flags
    local pkgs
    # [ @ version=version ]
    # [ @ flags=flags ]
    # [ @ pkgs=pkgs ]

    if [[ "$1" == 'list' ]]; then
        echo "${pkgs}"
    elif [[ "$1" == 'update' ]] || [[ "$1" == 'upgrade' ]]; then
        local script="$(curl -fsSL https://raw.githubusercontent.com/raymond-u/dotfiles/HEAD/install.sh)"

        # Caveat: Watch out for version numbers that go over 10
        if [[ ! "$(bash -c "${script}" -s -v)" > "${version}" ]]; then
            echo 'Home environment is up-to-date.'
            return 0
        fi

        bash -c "${script}" -s -u $(echo "${flags}")
    elif [[ "$1" == 'dev' ]]; then
        if [[ -z "${2+_}" ]] || [[ "$2" == 'help' ]]; then
            echo 'Usage:'
            echo '  home-env dev [command]'
            echo
            echo 'Commands:'
            echo '  help            --  Show this help message.'
            echo '  encrypt         --  Encrypt a string to a pre-processing macro.'
            echo '  encrypt [file]  --  Encrypt a file to a tar.gz archive.'
        elif [[ "$2" == 'encrypt' ]]; then
            if [[ -z "${3+_}" ]]; then
                local string
                IFS= read -r -d $'\04' string'?Please enter a string to encrypt. Use Ctrl+D to finish:'$'\n'
                printf '%s' $'\n''# [ ? age ] base64='
                age -R "${HOME}/.passage/store/.age-recipients" <<<"${string}" | base64 -w0
                echo
            else
                if [[ -d "$3" ]] || [[ -f "$3" ]]; then
                    if [[ -f "$(dirname "$3")/archive.age" ]]; then
                        echo 'Error: archive already exists.' >&2
                        return 1
                    fi
                    tar --exclude ".DS_Store" -cz -C "$(dirname "$3")" "$(basename "$3")" | base64 -w0 | age -R "${HOME}/.passage/store/.age-recipients" | base64 -w0 >"$(dirname "$3")/archive.age"
                    echo 'Encrypted archive created successfully.'
                else
                    echo 'Error: file not found.' >&2
                    return 1
                fi
            fi
        else
            echo 'Error: unknown command. Use "home-env dev help" to show help.' >&2
            return 1
        fi
    elif [[ "$1" == 'version' ]]; then
        echo "Raymond's home environment ${version}"
    elif [[ -z "${1+_}" ]] || [[ "$1" == 'help' ]]; then
        echo 'Usage:'
        echo '  home-env [command]'
        echo
        echo 'Commands:'
        echo '  help     --  Show this help message.'
        echo '  list     --  List packages installed with home environment.'
        echo '  update   --  Update dotfiles and installed packages.'
        echo '  upgrade  --  Same as update.'
        echo '  dev      --  Use "dev help" to show help.'
        echo '  version  --  Print version number and exit.'
    else
        echo 'Error: unknown command. Use "home-env help" to show help.' >&2
        return 1
    fi
}
# [ can_sudo start ]
port() {
    if (( $# == 0 )); then
        sudo lsof -iTCP -sTCP:LISTEN -n -P
    else
        local command='sudo lsof -iTCP -sTCP:LISTEN -n -P'
        for (( i = 1; i <= $#; i++ )); do
            if (( i == $# )); then
                command="${command} | rg -i '${(P)i}'"
            else
                command="${command} | rg -i --color=always '${(P)i}'"
            fi
        done
        eval "${command}"
    fi
}
# [ can_sudo end ]
weather() {
    curl -fsS 'wttr.in/'"$1"'?mMAF'
}

# Source local .zshrc
if [[ -f "${HOME}/.zshrc.local" ]]; then
    source "${HOME}/.zshrc.local"
fi

# [ is_macos start ]
# Initialize command-not-found
# [ is_macos_arm64 start ]
if [[ -f "$(brew --prefix)/Library/Taps/homebrew/homebrew-command-not-found/handler.sh" ]]; then
    source "$(brew --prefix)/Library/Taps/homebrew/homebrew-command-not-found/handler.sh"
fi
# [ is_macos_arm64 end ]
# [ ! is_macos_arm64 start ]
if [[ -f "$(brew --prefix)/Homebrew/Library/Taps/homebrew/homebrew-command-not-found/handler.sh" ]]; then
    source "$(brew --prefix)/Homebrew/Library/Taps/homebrew/homebrew-command-not-found/handler.sh"
fi
# [ ! is_macos_arm64 end ]
# [ is_macos end ]

# Initialize zinit
source "${HOME}/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load themes
zinit lucid depth"1" light-mode for                                                                                   \
    atload"zstyle ':completion:*' list-colors \${(s.:.)LS_COLORS}"                                                    \
        trapd00r/LS_COLORS                                                                                            \
    atload"[[ ! -f ${HOME}/.config/powerlevel10k/p10k.zsh ]] || source ${HOME}/.config/powerlevel10k/p10k.zsh"        \
        romkatv/powerlevel10k

# Load plugins
zinit wait lucid depth"1" for                                                                                         \
    atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit"                                                                       \
    compile"lib/{*ftb*,zsh-ls-colors/ls-colors.zsh}"                                                                  \
    blockf                                                                                                            \
        Aloxaf/fzf-tab                                                                                                \
    atinit"ZSH_FZF_HISTORY_SEARCH_FZF_ARGS='+s +m --reverse --height=80%'; ZSH_FZF_HISTORY_SEARCH_END_OF_LINE=true"   \
        joshskidmore/zsh-fzf-history-search                                                                           \
    zsh-users/zsh-autosuggestions                                                                                     \
    zdharma-continuum/fast-syntax-highlighting

# Load completions
zinit wait lucid depth"1" blockf for                                                                                  \
    # [ is_linux start ]
    conda-incubator/conda-zsh-completion                                                                              \
    spwhitt/nix-zsh-completions                                                                                       \
    # [ is_linux end ]
    zsh-users/zsh-completions                                                                                         \
    atload"zicdreplay"                                                                                                \
        zdharma-continuum/null

# Lazy-load plugins
zinit wait lucid depth"1" light-mode for                                                                              \
    trigger-load"!glo;!gd;!ga;!grh;!gi;!gcf;!gcb;!gbd;!gct;!gco;!grc;!gclean;!gss;!gcp;!grb;!gbl;!gfu"                \
        wfxr/forgit                                                                                                   \
    trigger-load"!ugit"                                                                                               \
        Bhupesh-V/ugit                                                                                                \
    trigger-load"!x"                                                                                                  \
        OMZ::plugins/extract

# [ is_macos start ]
# Initialize command-not-found
if [[ -f "$(brew --prefix)/Homebrew/Library/Taps/homebrew/homebrew-command-not-found/handler.sh" ]]; then
    source "$(brew --prefix)/Homebrew/Library/Taps/homebrew/homebrew-command-not-found/handler.sh"
fi
# [ is_macos end ]

# Initialize direnv
eval "$(direnv hook zsh)"

# Initialize the fuck
eval "$(thefuck --alias fk)"

# Initialize zoxide
eval "$(zoxide init zsh)"
alias cd='z'

# [ is_linux start ]
# Initialize conda
eval "$("${HOME}/opt/miniconda3/bin/conda" shell.zsh hook)"

# Initialize rust
source "${HOME}/.cargo/env"
# [ is_linux end ]

# Hook up shell integration
WEZTERM_SHELL_SKIP_ALL=0 source "${HOME}/.config/wezterm/shell-integration.sh"
