#!/usr/bin/env bash
#
# Automate Raymond's home environment setup.

# Unofficial bash strict mode
set -euo pipefail

#################################
# Constants
#################################

# Repo
repo=https://github.com/raymond-u/dotfiles.git
version='0.11.1'

# Scripts
crypto=src/crypto.sh
linux_reminders=src/linux/reminders.sh
preprocess=src/preprocess.sh
macos_reminders=src/macos/reminders.sh
set_defaults=src/macos/set_defaults.sh

# Config files
aria2=src/aria2/aria2.conf
bottom=src/bottom/bottom.toml
brewfile=src/homebrew/Brewfile
clash_archive=src/clash/archive.age
direnvrc=src/direnv/direnvrc
fastfetch=src/fastfetch/config.jsonc
gitconfig=src/git/config
gitignore=src/git/ignore
htoprc=src/htop/htoprc
hushlogin=src/misc/.hushlogin
karabiner_rules=src/karabiner/my_rules.json
mpv_conf=src/mpv/mpv.conf
mpv_input=src/mpv/input.conf
mpv_shaders=src/mpv/shaders
nix_env=src/nix/env.nix
nvchad=src/nvchad
p10k=src/powerlevel10k/p10k.zsh
passage_archive=src/passage/archive.age
ssh_archive=src/ssh/archive.age
taskrc=src/taskwarrior/taskrc
wezterm=src/wezterm/wezterm.lua
wgetrc=src/wget/wgetrc
yabairc=src/yabai/yabairc
zshenv=src/zsh/.zshenv
zshrc=src/zsh/.zshrc
zshrclocal=src/zsh/.zshrc.local

# Package list
brew_pkgs=(
    '# Shells'
    '  bash'
    '  zsh'
    ''
    '# System Commands'
    '  coreutils'
    '  findutils'
    '  gawk'
    '  gnu-getopt'
    '  gnu-sed'
    '  less'
    ''
    '# General Commands'
    '  bat'
    '  eza'
    '  fd'
    '  fzf'
    '  hexyl'
    '  ripgrep'
    '  sd'
    '  tree'
    '  zoxide'
    ''
    '# System Utilities'
    '  bottom'
    '  cpufetch'
    '  duf'
    '  fastfetch'
    '  htop'
    '  ncdu'
    '  procs'
    ''
    '# General Utilities'
    '  age'
    '  direnv'
    '  hyperfine'
    '  onefetch'
    '  pandoc'
    '  rename'
    '  rsync'
    '  task'
    '  tealdeer'
    ''
    '# Services'
    '  yabai'
    ''
    '# Media Viewers'
    '  chafa'
    ''
    '# Text Editors'
    '  nano'
    '  neovim'
    ''
    '# Web'
    '  aria2'
    '  oha'
    '  openssh'
    '  qrcp'
    '  wget'
    '  xh'
    ''
    '# Development'
    '  dotnet'
    '  node'
    '  openjdk'
    '  python'
    '  r'
    '  uv'
    ''
    '# Fonts'
    '  font-sarasa-gothic'
)
cask_pkgs=(
    '# Academics'
    '  zotero'
    ''
    '# IDE'
    '  pycharm'
    '  rider'
    '  visual-studio-code'
    '  webstorm'
    ''
    '# Media Viewers'
    '  iina'
    '  xnviewmp'
    ''
    '# Productivity'
    '  karabiner-elements'
    '  raycast'
    ''
    '# Terminal'
    '  wezterm'
    ''
    '# Utilities'
    '  aldente'
    '  basictex'
    '  keka'
    '  shottr'
    '  xnconvert'
    ''
    '# Web Browser'
    '  google-chrome'
)
nix_pkgs=(
    '# Shells'
    '  bash'
    '  zsh'
    ''
    '# Terminal'
    '  wezterm'
    ''
    '# System Commands'
    '  coreutils'
    '  findutils'
    '  gawk'
    '  gnu-sed'
    '  less'
    ''
    '# General Commands'
    '  bat'
    '  eza'
    '  fd'
    '  fzf'
    '  hexyl'
    '  ripgrep'
    '  sd'
    '  tree'
    '  zoxide'
    ''
    '# System Utilities'
    '  bottom'
    '  cpufetch'
    '  duf'
    '  fastfetch'
    '  htop'
    '  ncdu'
    '  procs'
    ''
    '# General Utilities'
    '  age'
    '  direnv'
    '  hyperfine'
    '  onefetch'
    '  p7zip'
    '  pandoc'
    '  rename'
    '  taskwarrior3'
    '  tealdeer'
    '  unrar'
    ''
    '# Media Viewers'
    '  chafa'
    ''
    '# Text Editors'
    '  nano'
    '  neovim'
    ''
    '# Web'
    '  aria2'
    '  curl'
    '  oha'
    '  openssh'
    '  qrcp'
    '  wget'
    '  xh'
    ''
    '# Development'
    '  dotnet-sdk'
    '  nodejs'
    '  openjdk'
    '  uv'
)

# Colors
no_color=$'\e[0m'
black=$'\e[0;30m'
red=$'\e[0;31m'
green=$'\e[0;32m'
yellow=$'\e[0;33m'
blue=$'\e[0;34m'
purple=$'\e[0;35m'
cyan=$'\e[0;36m'
white=$'\e[0;37m'

#################################
# Global variables
#################################

# Script settings
dry_run=false
update=false
os_flags_counter=0
architecture=
log_file=
tmpdir=

# Config flags
is_linux=false
is_macos=false
is_macos_arm64=false
can_sudo=false
has_identity=false
install_cask=false
use_mirror=false
use_single=false
use_bwrap=false
use_chroot=false
use_proot=false

config_flags=(
    'is_linux'
    'is_macos'
    'is_macos_arm64'
    'can_sudo'
    'has_identity'
    'install_cask'
    'use_mirror'
    'use_single'
    'use_bwrap'
    'use_chroot'
    'use_proot'
)

# Config settings
identity_file=
passphrase=

# Misc
temp_stdout=
temp_stderr=
reminders=()

#################################
# Functions
#################################

print_help() {
    echo 'Usage:'
    echo '  bash install.sh [options...]'
    echo "  Automate Raymond's home environment setup."
    echo
    echo 'Options:'
    echo '  -h, --help              Show help message and exit.'
    echo '  -v, --version           Show version information and exit.'
    echo '  -u, --update            Update the home environment. Intended for internal use only.'
    echo '  -n, --dry-run           Print info, but do not change anything.'
    echo '  --is-linux              Force the script to identify the OS as Linux.'
    echo '  --is-macos              Force the script to identify the OS as macOS (x86_64).'
    echo '  --is-macos-arm64        Force the script to identify the OS as macOS (arm64).'
    echo '  --can-sudo              Use sudo when necessary.'
    echo '  --has-identity          Use an identity file to decrypt secrets.'
    echo '  --identity-file         Specify the identity file.'
    echo '  --install-cask          Install GUI applications for macOS using Homebrew and Cask.'
    echo '  --use-mirror            Use USTC mirrors for faster downloads in China.'
}

print_welcome() {
    if is_true update; then
        log_info 'Updating the home environment...'
        return
    fi

    echo "${cyan}"
    cat <<'EOF'
______                                      _ _
| ___ \                                    | ( )
| |_/ /__ _ _   _ _ __ ___   ___  _ __   __| |/ ___
|    // _` | | | | '_ ` _ \ / _ \| '_ \ / _` | / __|
| |\ \ (_| | |_| | | | | | | (_) | | | | (_| | \__ \
\_| \_\__,_|\__, |_| |_| |_|\___/|_| |_|\__,_| |___/
             __/ |
            |___/
 _   _                        _____             _____      _
| | | |                      |  ___|           /  ___|    | |
| |_| | ___  _ __ ___   ___  | |__ _ ____   __ \ `--.  ___| |_ _   _ _ __
|  _  |/ _ \| '_ ` _ \ / _ \ |  __| '_ \ \ / /  `--. \/ _ \ __| | | | '_ \
| | | | (_) | | | | | |  __/ | |__| | | \ V /  /\__/ /  __/ |_| |_| | |_) |
\_| |_/\___/|_| |_| |_|\___| \____/_| |_|\_/   \____/ \___|\__|\__,_| .__/
                                                                    | |
                                                                    |_|

EOF
    echo "Welcome! This script is set to install Raymond's home environment onto your system."

    if is_true dry_run; then
        echo 'Dry run mode activated. No changes will be made.'
    else
        echo 'For the cautious, we offer a dry run mode '-n/--dry-run' to prevent inadvertent changes.'
    fi

    echo

    if is_true is_linux; then
        echo 'Linux environment detected. Nix will be used as the package manager.'
    elif is_true is_macos_arm64; then
        echo 'macOS (arm64) environment detected. Homebrew will be used as the package manager.'
    elif is_true is_macos; then
        echo 'macOS (x86_64) environment detected. Homebrew will be used as the package manager.'
    fi

    echo "Get ready for a comprehensive shell setup, installation of common packages, and ready-to-use development environment.${no_color}"

    prompt_for_continue 'Shall we proceed?'
}

log_error() {
    echo "${red}${1:-}${no_color}" >&2
}

log_info() {
    echo "${!2:-${blue}}${1:-}${no_color}"
}

log_section() {
    echo
    echo "${cyan}#################### $1 ####################${no_color}"
}

prompt_for_continue() {
    local _
    read -srp $'\n'"${yellow}$1 Press any key to continue. >${no_color}" -n1 _
    echo
}

prompt_for_passphrase() {
    read -srp $'\n'"${yellow}$1 >${no_color}" "$2"
    echo
}

prompt_for_string() {
    read -rp $'\n'"${yellow}$1 >${no_color}" "$2"
    echo
}

prompt_for_yesno() {
    local yesno
    yesno="$([[ "$2" == 'y' ]] && echo '(Y/n)' || echo '(y/N)')"

    while true; do
        read -rp $'\n'"${yellow}$1 ${yesno}>${no_color}" -n1 "$3"

        case "${!3}" in
            [Yy]) declare -g "$3"=true; break ;;
            [Nn]) declare -g "$3"=false; break ;;
            '') declare -g "$3"="$([[ "$2" == 'y' ]] && echo true || echo false)"; break ;;
        esac
    done
    echo
}

is_dry_run() {
    if ! is_true dry_run; then
        return 1
    fi

    echo "${yellow}In dry run mode. Skipping.${no_color}"
}

is_true() {
    if [[ -z "${!1}" ]] || [[ "${!1}" == false ]]; then
        return 1
    fi
}

join_by_newline() {
    local IFS=$'\n'
    printf '%s' "$*"
}

get_package_list() {
    if is_true is_linux; then
        printf '%s' "$(join_by_newline "${nix_pkgs[@]}")"
    elif is_true is_macos; then
        if is_true install_cask; then
            printf '%s' "$(join_by_newline "${brew_pkgs[@]}")" $'\n\n----- GUI Applications -----\n\n' "$(join_by_newline "${cask_pkgs[@]}")"
        else
            printf '%s' "$(join_by_newline "${brew_pkgs[@]}")"
        fi
    fi
}

run_with_nix_wrapper() {
    if ! is_dry_run; then
        if is_true use_bwrap; then
                bwrap --ro-bind  /etc           /etc   \
                      --ro-bind  /usr           /usr   \
                      --bind     /home          /home  \
                      --bind     /opt           /opt   \
                      --bind     /root          /root  \
                      --bind     /run           /run   \
                      --bind     /sys           /sys   \
                      --bind     /tmp           /tmp   \
                      --bind     /var           /var   \
                      --symlink  /usr/bin       /bin   \
                      --symlink  /usr/lib       /lib   \
                      --symlink  /usr/lib64     /lib64 \
                      --symlink  /usr/sbin      /sbin  \
                      --dev-bind /dev           /dev   \
                      --proc     /proc                 \
                      --bind     "${HOME}/.nix" /nix   \
                      bash -c "[[ ! -e '${HOME}/.nix-profile/etc/profile.d/nix.sh' ]] || source '${HOME}/.nix-profile/etc/profile.d/nix.sh'; $1"
        elif is_true use_chroot; then
            "${HOME}/.local/bin/nix-user-chroot" "${HOME}/.nix" bash -c "[[ ! -e '${HOME}/.nix-profile/etc/profile.d/nix.sh' ]] || source '${HOME}/.nix-profile/etc/profile.d/nix.sh'; $1"
        elif is_true use_proot; then
            # TODO: support PRoot
            :
        elif [[ -n "$(command -v "${1%% *}")" ]]; then
            eval "$1"
        fi
    fi
}

preprocess_file() {
    local flags=()

    for flag in "${config_flags[@]}"; do
        [[ "${!flag}" == false ]] || flags+=("${flag}")
    done

    local pairs=(
        '--flags' "${flags[*]}"
        '--pkgs' "$(get_package_list)"
        '--version' "${version}"
    )

    if is_true has_identity; then
        bash "${preprocess}" -i "${tmpdir}/dotfiles/$1" -o "${tmpdir}/dotfiles/$1.pd" -s "${crypto}" -p "$(command -v age)" -f "${identity_file}" "${pairs[@]}" "${flags[@]}" <<<"${passphrase}"
    else
        bash "${preprocess}" -i "${tmpdir}/dotfiles/$1" -o "${tmpdir}/dotfiles/$1.pd" "${pairs[@]}" "${flags[@]}"
    fi

    printf '%s' "${tmpdir}/dotfiles/$1.pd"
}

put_file() {
    log_info "Put $1 config file to $3."

    if ! is_dry_run; then
        if [[ -e "$3" ]]; then
            if ! is_true update; then
                log_info "$1 config file already exists. Rename it to $3.old."
                reminders+=("$1: old config file lingers in $3.old.")
                mv "$3" "$3.old"
            fi
        else
            mkdir -p "$(dirname "$3")"
        fi

        cp "$(preprocess_file "$2")" "$3"
    fi
}

put_file_if_not_exists() {
    if [[ ! -e "$3" ]]; then
        log_info "Put $1 config file to $3."

        if ! is_dry_run; then
            mkdir -p "$(dirname "$3")"
            cp "$(preprocess_file "$2")" "$3"
        fi
    fi
}

put_folder() {
    log_info "Put $1 config files to $3."

    if ! is_dry_run; then
        if [[ -e "$3" ]]; then
            if ! is_true update; then
                log_info "$1 config directory already exists. Rename it to $3.old."
                reminders+=("$1: old config files linger in $3.old.")
                mv "$3" "$3.old"
            else
                rm -rf "$3"
            fi
        else
            mkdir -p "$(dirname "$3")"
        fi

        cp -r "$2" "$3"
    fi
}

put_encrypted_file() {
    if is_true has_identity; then
        log_info "Put $1 config files to $4."

        if ! is_dry_run; then
            if [[ -e "$4" ]]; then
                if ! is_true update; then
                    log_info "$1 config directory already exists. Rename it to $4.old."
                    reminders+=("$1: old config files linger in $4.old.")
                    mv "$4" "$4.old"
                fi
            fi

            mkdir -p "$3"
            bash "${crypto}" -p "$(command -v age)" -d -i "${identity_file}" <<<"$(<"$2") ${passphrase}" | base64 -d | tar -xzC "$3"
        fi
    fi
}

clean_up() {
    log_info 'Cleaning up...'
    while popd &>/dev/null; do :; done
    rm -rf "${tmpdir}"
    exec 1>&"${temp_stdout}" 2>&"${temp_stderr}" {temp_stdout}>&- {temp_stderr}>&-

    trap ERR INT TERM
}

#################################
# Main
#################################

main() {
    # Check Bash version
    if (( ${BASH_VERSINFO:-0} < 4 )); then
        log_error 'Error: Bash 4 or later is required.'
        exit 1
    fi

    # Parse arguments
    while (( $# > 0 )); do
        case "$1" in
            -h|--help)
                print_help
                exit 0
                ;;
            -v|--version)
                echo "${version}"
                exit 0
                ;;
            -u|--update)
                update=true
                shift
                ;;
            -n|--dry-run)
                dry_run=true
                shift
                ;;
            --is-linux)
                (( os_flags_counter++ ))
                is_linux=true
                shift
                ;;
            --is-macos)
                (( os_flags_counter++ ))
                is_macos=true
                shift
                ;;
            --is-macos-arm64)
                (( os_flags_counter++ ))
                is_macos=true
                is_macos_arm64=true
                shift
                ;;
            --can-sudo)
                can_sudo=true
                shift
                ;;
            --has-identity)
                has_identity=true
                shift
                ;;
            --identity-file)
                identity_file="$2"
                shift
                shift
                ;;
            --install-cask)
                install_cask=true
                shift
                ;;
            --use-mirror)
                use_mirror=true
                shift
                ;;
            -*)
                log_error "Error: unknown flag \"$1\"."
                print_help
                exit 1
                ;;
            *)
                if [[ ! "${config_flags[*]}" =~ "$1" ]]; then
                    log_error "Error: unknown flag \"$1\"."
                    exit 1
                fi
                declare -g "$1"=true
                shift
                ;;
        esac
    done

    # Quit if OS is specified more than once
    if (( os_flags_counter > 1 )); then
        log_error 'Error: please ensure OS flags are specified only once, if at all.'
        exit 1
    fi

    # Determine architecture
    case "$(uname -m)" in
        x86_64)
            architecture='x86_64'
            ;;
        aarch64|arm64)
            architecture='aarch64'
            ;;
        *)
            log_error 'Error: unknown architecture.'
            log_error 'Supported architectures:'
            log_error '  - aarch64'
            log_error '  - x86_64'
            exit 1
            ;;
    esac

    # Find out on which OS it is running
    if (( os_flags_counter == 0 )); then
        case "${OSTYPE}" in
            darwin*)
                is_macos=true
                [[ "${architecture}" != 'aarch64' ]] || is_macos_arm64=true
                can_sudo=true
                ;;
            linux-gnu*)
                is_linux=true
                ;;
            *)
                log_error 'Error: unknown OS.'
                log_error 'Supported platforms:'
                log_error '  - Linux'
                log_error '  - macOS (compatible with both Intel-based and Apple Silicon machines)'
                log_error
                log_error 'You can force the script to run by passing the correct argument. For more details, run the script with "-h" or "--help".'
                exit 1
                ;;
        esac
    fi

    # Check the identity file
    if is_true identity_file; then
        if [[ ! -f "${identity_file}" ]]; then
            log_error 'Error: the identity file does not exist.'
            exit 1
        fi

        has_identity=true
    fi

    # Check prerequisites
    _prerequisites=()
    if is_true is_linux; then
        _prerequisites=('chmod' 'curl' 'dirname' 'git' 'ls' 'mkdir' 'mktemp' 'mv' 'readlink' 'uname')
    elif is_true is_macos; then
        _prerequisites=('base64' 'curl' 'dirname' 'expect' 'git' 'ls' 'make' 'mkdir' 'mktemp' 'mv' 'perl' 'tar' 'uname')
    fi
    for _program in "${_prerequisites[@]}"; do
        if [[ -z "$(command -v "${_program}")" ]]; then
            log_error "Error: ${_program} is not installed."
            exit 1
        fi
    done
    unset _prerequisites
    unset _program

    # Redirect output
    log_file="$(is_true update && echo "${PWD}/home_env_update.log" || echo "${PWD}/home_env_install.log")"
    exec {temp_stdout}>&1 {temp_stderr}>&2 &> >(tee "${log_file}")

    # Create temporary directory
    tmpdir="$(mktemp -d 2>/dev/null || mktemp -d -t 'tmp')"

    # Intercept signals
    trap 'clean_up; exit 1' ERR INT TERM

    # Print welcome messages
    print_welcome

    # Prompt for use of sudo
    if ! is_true can_sudo && ! is_true update; then
        prompt_for_yesno 'Can we use sudo?' 'y' can_sudo
    fi

    # Propmt for use of mirrors
    if ! is_true use_mirror && ! is_true update; then
        prompt_for_yesno 'Do you want to use USTC mirrors for faster downloads in China?' 'n' use_mirror
    fi

    # Clone dotfiles into temp directory
    log_info 'Cloning repo into a temporary directory...'
    git clone --depth=1 --quiet "${repo}" "${tmpdir}/dotfiles"
    pushd "${tmpdir}/dotfiles" >/dev/null

    # Configure for Linux
    if is_true is_linux; then
        # Create empty folders
        log_info 'Create empty folders in the home directory.'
        is_dry_run || mkdir -p "${HOME}/.local/"{bin,opt,share/man} "${HOME}/.local/state/"{less,python,zsh} "${HOME}/"{downloads,playground}

        # Configure Nix
        if ! is_true update; then
            log_section 'Nix Configuration'

            # Install Nix
            if [[ -z "$(command -v nix-env)" ]]; then
                # Determine how to install Nix
                _nix_installation=
                if is_true can_sudo; then
                    # Check if SELinux has been disabled
                    ! selinuxenabled 2>/dev/null || sudo setenforce 'Permissive'
                    _nix_installation='multi-user'
                else
                    if [[ -d /nix ]]; then
                        # Sudo might not be needed since Nix has been installed once and its build users may still linger
                        if selinuxenabled 2>/dev/null; then
                            _nix_installation='single-user'
                            use_single=true
                        else
                            _nix_installation='multi-user'
                        fi
                    else
                        # Bubblewrap does not require user namespace support if it is installed as a setuid binary
                        if [[ "$(unshare --user --pid echo 'YES' 2>/dev/null)" == 'YES' ]]; then
                            if [[ -n "$(command -v bwrap)" ]]; then
                                _nix_installation='bubblewrap'
                                use_bwrap=true
                            else
                                _nix_installation='nix-user-chroot'
                                use_chroot=true
                            fi
                        else
                            _nix_installation='proot'
                            use_proot=true
                        fi
                    fi
                fi
                prompt_for_continue "Nix will be installed in ${_nix_installation} mode."
                # Add shared Nix configuration
                if is_true can_sudo; then
                    is_dry_run || sudo bash -c "mkdir -p /etc/nix; cat >>/etc/nix/nix.conf <<'EOF'
always-allow-substitutes = true
auto-optimise-store = true
experimental-features = flakes nix-command
max-jobs = auto
EOF"
                elif is_true use_bwrap || is_true use_chroot || is_true use_proot; then
                    if ! is_dry_run; then
                        mkdir -p "${HOME}/.config/nix"
                        cat >>"${HOME}/.config/nix/nix.conf" <<'EOF'
always-allow-substitutes = true
auto-optimise-store = true
build-users-group =
experimental-features = flakes nix-command
max-jobs = auto
sandbox = false
EOF
                    fi
                else
                    if ! is_dry_run; then
                        mkdir -p "${HOME}/.config/nix"
                        cat >>"${HOME}/.config/nix/nix.conf" <<'EOF'
always-allow-substitutes = true
auto-optimise-store = true
experimental-features = flakes nix-command
max-jobs = auto
EOF
                    fi
                fi
                case "${_nix_installation}" in
                    multi-user)
                        log_info 'Installing Nix in multi-user mode...'
                        if ! is_dry_run; then
                            sh <(curl -fsSL https://nixos.org/nix/install) --daemon --no-channel-add --no-modify-profile --yes
                            source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
                        fi
                        ;;
                    single-user)
                        log_info 'Installing Nix in single-user mode...'
                        if ! is_dry_run; then
                            sh <(curl -fsSL https://nixos.org/nix/install) --no-daemon --no-channel-add --no-modify-profile --yes
                            source "${HOME}/.nix-profile/etc/profile.d/nix.sh"
                        fi
                        ;;
                    bubblewrap)
                        log_info 'Installing Nix in single-user mode using bubblewrap...'
                        is_dry_run || mkdir -p "${HOME}/.nix"
                        run_with_nix_wrapper 'sh <(curl -fsSL https://nixos.org/nix/install) --no-daemon --no-channel-add --no-modify-profile --yes'
                        reminders+=('Nix: note that you can only use Nix and the installed packages within the shell started by bubblewrap.')
                        reminders+=('Nix: this shell has restricted access to the host file system. You can add additional bindings if needed.')
                        ;;
                    nix-user-chroot)
                        log_info 'Installing Nix in single-user mode using nix-user-chroot...'
                        curl -L "https://github.com/nix-community/nix-user-chroot/releases/download/1.2.2/nix-user-chroot-bin-1.2.2-${architecture}-unknown-linux-musl" >"${tmpdir}/nix-user-chroot"
                        chmod +x "${tmpdir}/nix-user-chroot"
                        if ! is_dry_run; then
                            mkdir -p "${HOME}/.nix"
                            mv "${tmpdir}/nix-user-chroot" "${HOME}/.local/bin"
                            run_with_nix_wrapper "sh <(curl -fsSL https://nixos.org/nix/install) --no-daemon --no-channel-add --no-modify-profile --yes"
                        fi
                        reminders+=('Nix: note that you can only use Nix and the installed packages within the shell started by nix-user-chroot.')
                        ;;
                    proot)
                        prompt_for_yesno "Nix must be installed using PRoot, but support for PRoot is not complete and haven't been tested. Do you still want to continue?" 'n' _yesno
                        if ! is_true _yesno; then
                            clean_up
                            exit 0
                        fi
                        unset _yesno
                        # TODO: support PRoot
                        log_info 'Installing Nix in non-root mode using proot...'
                        curl -L "https://github.com/proot-me/proot/releases/download/v5.4.0/proot-v5.4.0-${architecture}-static" >"${tmpdir}/proot"
                        chmod +x "${tmpdir}/proot"
                        log_info 'A shell will be spawned by PRoot. Please enter "sh <(curl -fsSL https://nixos.org/nix/install) --no-daemon --no-channel-add --no-modify-profile --yes" in the new shell to install Nix.'
                        log_info "After Nix installation is finished, please add a channel and enter \"nix-env -i -f '${tmpdir}/dotfiles/${nix_env}'\" to set up the home environment."
                        log_info "When done, please enter exit."
                        if ! is_dry_run; then
                            mkdir -p "${HOME}/.nix"
                            mv "${tmpdir}/proot" "${HOME}/.local/bin"
                            "${HOME}/.local/bin/proot" -b "${HOME}/.nix:/nix"
                        fi
                        reminders+=('Nix: note that you can only use Nix and the installed packages within the shell started by PRoot.')
                        ;;
                esac
                unset _nix_installation
            fi

            # Use mirror for Nix
            if is_true use_mirror; then
                log_info 'Use USTC mirror for Nix.'
                if ! is_dry_run; then
                    mkdir -p "${HOME}/.config/nix"
                    echo 'substituters = https://mirrors.ustc.edu.cn/nix-channels/store https://cache.nixos.org/' >>"${HOME}/.config/nix/nix.conf"
                    run_with_nix_wrapper 'nix-channel --add https://mirrors.ustc.edu.cn/nix-channels/nixpkgs-unstable nixpkgs'
                    if is_true can_sudo; then
                        echo 'trusted-substituters = https://mirrors.ustc.edu.cn/nix-channels/store' | sudo tee -a /etc/nix/nix.conf
                        sudo systemctl restart nix-daemon
                    fi
                fi
            else
                # Add default channel
                run_with_nix_wrapper 'nix-channel --add https://nixos.org/channels/nixpkgs-unstable'
            fi
        fi

        # Install from Nix
        log_section 'Nix Packages'
        log_info "$(get_package_list)" yellow

        # Prompt for confirmation of package installation
        prompt_for_continue 'About to install the above packages from Nix.'
        log_info 'Installing packages...'
        if ! is_dry_run; then
            if [[ ! -f "${HOME}/.config/nixpkgs/config.nix" || ! "$(<"${HOME}/.config/nixpkgs/config.nix")" =~ '{ allowUnfree = true; }' ]]; then
                mkdir -p "${HOME}/.config/nixpkgs"
                echo '{ allowUnfree = true; }' >>"${HOME}/.config/nixpkgs/config.nix"
            fi

            # Might already have nix in PATH when updating
            run_with_nix_wrapper "nix-channel --update; nix-env -i -f '${tmpdir}/dotfiles/${nix_env}'"
        fi

        # Configure Zsh
        if ! is_true update; then
            log_section 'Zsh Configuration'

            # Install Zinit
            log_info 'Installing Zinit...'
            is_dry_run || NO_EDIT=1 NO_TUTORIAL=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
            reminders+=('Zinit: Zinit will self-update when the shell reloads.')
            reminders+=('Zinit: you can run "zinit self-update" to compile Zinit (optional).')

            # Change the login shell to Zsh
            if [[ ! "${SHELL}" =~ 'zsh'$ ]] && ! is_true use_bwrap && ! is_true use_chroot && ! is_true use_proot; then
                _can_use_zsh=true
                if [[ ! "$(</etc/shells)" =~ "$(readlink -f "$(command -v zsh)")" ]]; then
                    if is_true can_sudo; then
                        log_info "Add Zsh to /etc/shells."
                        is_dry_run || sudo bash -c 'readlink -f "$1" >>/etc/shells' -s "$(command -v zsh)"
                    else
                        log_error "Warning: Zsh is not listed as a valid shell. Sudo is needed to add it to /etc/shells."
                        log_error "Abort changing the login shell to Zsh."
                        _can_use_zsh=false
                    fi
                fi
                if is_true _can_use_zsh; then
                    log_info 'Change the login shell to Zsh.'
                    is_dry_run || chsh -s "$(readlink -f "$(command -v zsh)")"
                fi
                unset _can_use_zsh
            fi
        fi

        # Configure WezTerm
        log_info 'Set up shell integration for WezTerm.'
        if ! is_dry_run; then
            mkdir -p "${HOME}/.config/wezterm"
            curl -fsSL https://raw.githubusercontent.com/wez/wezterm/main/assets/shell-integration/wezterm.sh -o "${HOME}/.config/wezterm/shell-integration.sh"
        fi
        if is_true use_bwrap || is_true use_chroot || is_true use_proot; then
            reminders+=('WezTerm: WezTerm multiplexer won'\''t work out of the box.')
            reminders+=("WezTerm: You need to run 'nix bundle nixpkgs#wezterm' and put the output binary to your PATH, then run 'wezterm-mux-server --daemonize' to start the server.")
        fi

        # Install with uv
        if is_true update; then
            log_info 'Updating packages with uv...'
            run_with_nix_wrapper 'uv tool upgrade --all'
        else
            log_info 'Installing packages with uv...'
            log_info 'Installing Poetry...'
            run_with_nix_wrapper 'uv tool install poetry'
        fi

        # Configure tealdeer
        log_info 'Fetch caches for tealdeer.'
        run_with_nix_wrapper 'tldr --update'

        # Configure Neovim
        if ! is_true update; then
            log_info 'Clean up folders for Neovim.'

            is_dry_run || rm -rf "${HOME}/.local/share/nvim"
            reminders+=('Neovim: Neovim will self-update when it is launched for the first time.')
            reminders+=('Neovim: after that, run ":MasonInstallAll" to install LSP servers and other tools.')
        fi

        # Configure Conda
        if ! is_true update; then
            log_section 'Conda Configuration'

            # Prompt for installation of Conda
            prompt_for_yesno 'Do you want to install Miniforge (Conda)?' 'y' _yesno
            if is_true _yesno; then
                # Use mirror for Conda
                if is_true use_mirror; then
                    log_info 'Use USTC mirror for Conda.'
                    if ! is_dry_run; then
                        mkdir -p "${HOME}/.config/conda"
                        cat >"${HOME}/.config/conda/.condarc" <<'EOF'
channels:
  - conda-forge
  - bioconda
channel_alias: https://mirrors.ustc.edu.cn/anaconda/cloud
always_yes: true
show_channel_urls: true
EOF
                    fi
                fi

                # Install Conda
                log_info 'Installing Conda...'
                if ! is_dry_run; then
                    curl -fsSL "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-${architecture}.sh" >"${tmpdir}/miniforge.sh"
                    bash "${tmpdir}/miniforge.sh" -b -p "${HOME}/.local/opt/miniforge"
                fi
            fi
            unset _yesno
        fi

        # Configure Node.js
        if ! is_true update; then
            log_section 'Node.js Configuration'

            # Enable corepack
            log_info 'Enable corepack.'
            run_with_nix_wrapper "corepack enable --install-directory '${HOME}/.local/bin'"
        fi

        # Configure Rust
        if ! is_true update; then
            log_section 'Rust Configuration'

            # Prompt for installation of Rust
            prompt_for_yesno 'Do you want to install the Rust toolchain and rust-script?' 'y' _yesno
            if is_true _yesno; then
                # Connecting to crates is fast enough, so no need to use a mirror
                if is_true use_mirror; then
                    log_info 'Cargo does not require the use of a mirror.'
                fi

                # Install Rust
                log_info 'Installing Rust...'
                if ! is_dry_run; then
                    curl -fsSL https://sh.rustup.rs | RUSTUP_HOME="${HOME}/.local/opt/rustup" sh -s -- -y --no-modify-path
                    source "${HOME}/.cargo/env"
                fi

                # Install rust-script
                log_info 'Installing rust-script...'
                is_dry_run || RUSTUP_HOME="${HOME}/.local/opt/rustup" cargo install rust-script
            fi
            unset _yesno
        fi

        # Set up dotfiles
        log_section 'Dotfiles Setup'
        put_file 'Aria2' "${aria2}" "${HOME}/.config/aria2/aria2.conf"
        put_file 'bottom' "${bottom}" "${HOME}/.config/bottom/bottom.toml"
        put_file 'direnv' "${direnvrc}" "${HOME}/.config/direnv/direnvrc"
        put_file 'fastfetch' "${fastfetch}" "${HOME}/.config/fastfetch/config.jsonc"
        put_file 'Git' "${gitconfig}" "${HOME}/.config/git/config"
        put_file 'Git' "${gitignore}" "${HOME}/.config/git/ignore"
        put_file 'htop' "${htoprc}" "${HOME}/.config/htop/htoprc"
        put_file 'login' "${hushlogin}" "${HOME}/.hushlogin"
        put_folder 'Neovim' "${nvchad}" "${HOME}/.config/nvim"
        put_file 'Powerlevel10k' "${p10k}" "${HOME}/.config/powerlevel10k/p10k.zsh"
        put_file 'Taskwarrior' "${taskrc}" "${HOME}/.config/task/taskrc"
        put_file 'Wget' "${wgetrc}" "${HOME}/.config/wget/wgetrc"
        put_file 'Zsh' "${zshenv}" "${HOME}/.zshenv"
        put_file 'Zsh' "${zshrc}" "${HOME}/.zshrc"
        put_file_if_not_exists 'Zsh' "${zshrclocal}" "${HOME}/.zshrc.local"

        # Reminders for Linux
        reminders+=('')
        source "$(preprocess_file "${linux_reminders}")"

    # Configure for macOS
    elif is_true is_macos; then
        # Create empty folders
        log_info 'Create empty folders in the home directory.'
        is_dry_run || mkdir -p "${HOME}/.local/"{bin,opt,share/man} "${HOME}/.local/state/"{less,python,zsh} "${HOME}/"{Developer,Playground}

        # Prompt for the identity file
        is_true has_identity || prompt_for_yesno 'Do you have the identity file? (Choose no if you have no idea what it is.)' 'n' has_identity
        if is_true has_identity && ! is_true identity_file; then
            if [[ -f "${HOME}/.passage/identities" ]]; then
                prompt_for_continue "Use the identity file located at ${HOME}/.passage/identities."
                identity_file="${HOME}/.passage/identities"
            else
                prompt_for_string 'Please enter the path to the identity file.' identity_file
                [[ -f "${identity_file}" ]] || has_identity=false
            fi
        fi

        # Request access to user directories if necessary
        if [[ "${identity_file}" =~ "${HOME}/Desktop" ]]; then
            ls "${HOME}/Desktop" >/dev/null
        elif [[ "${identity_file}" =~ "${HOME}/Documents" ]]; then
            ls "${HOME}/Documents" >/dev/null
        elif [[ "${identity_file}" =~ "${HOME}/Downloads" ]]; then
            ls "${HOME}/Downloads" >/dev/null
        fi

        # Prompt for the passphrase
        ! is_true has_identity || prompt_for_passphrase "Please enter the passphrase of the identity file. (If there isn't one, just hit enter.)" passphrase

        # Configure macOS
        if ! is_true update; then
            log_section 'macOS Configuration'
            log_info 'Configure general UI/UX settings.'
            log_info 'Configure trackpad, mouse and keyboard settings.'
            log_info 'Configure energy saving settings.'
            log_info 'Configure screen settings.'
            log_info 'Configure bluetooth accessory settings.'
            log_info 'Configure Disk Utility settings.'
            log_info 'Configure Dock, Dashboard and Mission Control settings.'
            log_info 'Configure Finder settings.'
            log_info 'Configure Mac App Store settings.'
            log_info 'Configure Mail settings.'
            log_info 'Configure Photos settings.'
            log_info 'Configure Safari settings.'
            log_info 'Configure Terminal settings.'
            log_info 'Configure TextEdit settings.'
            log_info 'Configure Time Machine settings.'
            is_dry_run || bash "${set_defaults}"
        fi

        # Configure Homebrew
        if ! is_true update; then
            log_section 'Homebrew Configuration'

            # Use mirror for Homebrew
            if is_true use_mirror; then
                log_info 'Use USTC mirror for Homebrew.'
                export HOMEBREW_BREW_GIT_REMOTE=https://mirrors.ustc.edu.cn/brew.git
                export HOMEBREW_CORE_GIT_REMOTE=https://mirrors.ustc.edu.cn/homebrew-core.git
                export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.ustc.edu.cn/homebrew-bottles
                export HOMEBREW_API_DOMAIN=https://mirrors.ustc.edu.cn/homebrew-bottles/api
            fi

            # Install Homebrew
            log_info 'Installing Homebrew...'
            is_dry_run || bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

            # One extra step required for Apple Silicon machines
            if is_true is_macos_arm64; then
                is_dry_run || eval "$(/opt/homebrew/bin/brew shellenv)"
            fi
        fi

        # Prompt for installation of GUI applications
        log_section 'Homebrew Packges'
        { is_true install_cask && ! is_true update; } || prompt_for_yesno 'Do you want to install GUI applications from Homebrew Cask?' 'y' install_cask

        # Prompt for confirmation of package installation
        log_info "$(get_package_list)" yellow
        prompt_for_continue 'About to install the above packages from Homebrew.'

        # Install from Homebrew
        log_info 'Installing packages...'
        if ! is_dry_run; then
            brew bundle --file="$(preprocess_file "${brewfile}")"

            # Configure openjdk
            sudo ln -sfn "$(brew --prefix)/opt/openjdk/libexec/openjdk.jdk" /Library/Java/JavaVirtualMachines/openjdk.jdk
        fi

        # Configure Zsh
        if ! is_true update; then
            log_section 'Zsh Configuration'

            # Install Zinit
            log_info 'Installing Zinit...'
            is_dry_run || NO_EDIT=1 NO_TUTORIAL=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
            reminders+=('Zinit: Zinit will self-update when the shell reloads.')
            reminders+=('Zinit: you can run "zinit self-update" to compile Zinit (optional).')

            # Change the login shell to Zsh
            if [[ ! "${SHELL}" =~ 'zsh'$ ]]; then
                if [[ ! "$(</etc/shells)" =~ "$(command -v zsh)" ]]; then
                    log_info "Add Zsh to /etc/shells."
                    is_dry_run || sudo bash -c 'command -v zsh >>/etc/shells'
                fi
                log_info 'Change the login shell to Zsh.'
                is_dry_run || chsh -s "$(command -v zsh)"
            fi
        fi

        # Configure WezTerm
        log_info 'Set up shell integration for WezTerm.'
        if ! is_dry_run; then
            mkdir -p "${HOME}/.config/wezterm"
            curl -fsSL https://raw.githubusercontent.com/wez/wezterm/main/assets/shell-integration/wezterm.sh -o "${HOME}/.config/wezterm/shell-integration.sh"
        fi

        # Install with uv
        if is_true update; then
            log_info 'Updating packages with uv...'
            is_dry_run || uv tool upgrade --all
        else
            log_info 'Installing packages with uv...'
            log_info 'Installing Poetry...'
            is_dry_run || uv tool install poetry
        fi

        # Configure tealdeer
        log_info 'Fetch caches for tealdeer.'
        is_dry_run || tldr --update

        # Configure Neovim
        if ! is_true update; then
            log_section 'Clean up folders for Neovim.'

            is_dry_run || rm -rf "${HOME}/.local/share/nvim"
            reminders+=('Neovim: Neovim will self-update when it is launched for the first time.')
            reminders+=('Neovim: after that, run ":MasonInstallAll" to install LSP servers and other tools.')
        fi

        # Configure Node.js
        if ! is_true update; then
            log_section 'Node.js Configuration'

            # Enable corepack
            log_info 'Enable corepack.'
            is_dry_run || corepack enable
        fi

        # Configure Rust
        if ! is_true update; then
            log_section 'Rust Configuration'

            # Prompt for installation of Rust
            prompt_for_yesno 'Do you want to install the Rust toolchain and rust-script?' 'y' _yesno
            if is_true _yesno; then
                # Connecting to crates is fast enough, so no need to use a mirror
                if is_true use_mirror; then
                    log_info 'Cargo does not require the use of a mirror.'
                fi

                # Install Rust
                log_info 'Installing Rust...'
                if ! is_dry_run; then
                    curl -fsSL https://sh.rustup.rs | RUSTUP_HOME="${HOME}/.local/opt/rustup" sh -s -- -y --no-modify-path
                    source "${HOME}/.cargo/env"
                fi

                # Install rust-script
                log_info 'Installing rust-script...'
                is_dry_run || RUSTUP_HOME="${HOME}/.local/opt/rustup" cargo install rust-script
            fi
            unset _yesno
        fi

        # Configure passage
        if is_true has_identity; then
            log_section 'Passage Setup'

            # Install passage
            if ! is_true update; then
                log_info 'Installing passage...'
                git clone --depth=1 --quiet https://github.com/FiloSottile/passage "${tmpdir}/passage"
                if ! is_dry_run; then
                    pushd "${tmpdir}/passage" >/dev/null
                    make "PREFIX=${HOME}/.local/opt/passage" install
                    ln -sf "${HOME}/.local/opt/passage/bin/passage" "${HOME}/.local/bin"
                    popd >/dev/null
                fi
            fi

            # Move the identity file
            if [[ "${identity_file}" != "${HOME}/.passage/identities" ]]; then
                prompt_for_yesno "Do you want to move the identity file to ${HOME}/.passage/identities?" 'y' _yesno
                if is_true _yesno; then
                    log_info "Move the identity file to ${HOME}/.passage/identities."
                    if ! is_dry_run; then
                        mv "${identity_file}" "${HOME}/.passage/identities"
                        identity_file="${HOME}/.passage/identities"
                    fi
                fi
                unset _yesno
            fi
        fi

        # Set up dotfiles
        log_section 'Dotfiles Setup'
        put_file 'Aria2' "${aria2}" "${HOME}/.config/aria2/aria2.conf"
        put_file 'bottom' "${bottom}" "${HOME}/.config/bottom/bottom.toml"
        put_encrypted_file 'Clash' "${clash_archive}" "${HOME}/.config" "${HOME}/.config/clash"
        put_file 'direnv' "${direnvrc}" "${HOME}/.config/direnv/direnvrc"
        put_file 'fastfetch' "${fastfetch}" "${HOME}/.config/fastfetch/config.jsonc"
        put_file 'Git' "${gitconfig}" "${HOME}/.config/git/config"
        put_file 'Git' "${gitignore}" "${HOME}/.config/git/ignore"
        put_file 'htop' "${htoprc}" "${HOME}/.config/htop/htoprc"
        put_file 'Karabiner' "${karabiner_rules}" "${HOME}/.config/karabiner/assets/complex_modifications/my_rules.json"
        put_file 'login' "${hushlogin}" "${HOME}/.hushlogin"
        put_file 'mpv' "${mpv_conf}" "${HOME}/.config/mpv/mpv.conf"
        put_file 'mpv' "${mpv_input}" "${HOME}/.config/mpv/input.conf"
        put_folder 'mpv' "${mpv_shaders}" "${HOME}/.config/mpv/shaders"
        put_folder 'Neovim' "${nvchad}" "${HOME}/.config/nvim"
        put_encrypted_file 'passage' "${passage_archive}" "${HOME}/.passage" "${HOME}/.passage/store"
        put_file 'Powerlevel10k' "${p10k}" "${HOME}/.config/powerlevel10k/p10k.zsh"
        put_encrypted_file 'SSH' "${ssh_archive}" "${HOME}" "${HOME}/.ssh"
        put_file 'Taskwarrior' "${taskrc}" "${HOME}/.config/task/taskrc"
        put_file 'WezTerm' "${wezterm}" "${HOME}/.config/wezterm/wezterm.lua"
        put_file 'Wget' "${wgetrc}" "${HOME}/.config/wget/wgetrc"
        put_file 'Yabai' "${yabairc}" "${HOME}/.config/yabai/yabairc"
        put_file 'Zsh' "${zshenv}" "${HOME}/.zshenv"
        put_file 'Zsh' "${zshrc}" "${HOME}/.zshrc"
        put_file_if_not_exists 'Zsh' "${zshrclocal}" "${HOME}/.zshrc.local"

        # Reminders for macOS
        if is_true has_identity; then
            reminders+=('')
            source "$(preprocess_file "${macos_reminders}")"
        fi
    fi

    # Report
    log_section 'Final Report'

    # Print reminders
    if (( ${#reminders[@]} > 0 )); then
        log_info 'Almost done. A few reminders:' yellow
        for _reminder in "${reminders[@]}"; do
            log_info "${_reminder}" yellow
        done
    else
        log_info 'Done.'
    fi
    unset _reminder
    echo
    ! is_true update || log_info 'You may consider updating Neovim and Zinit plugins manually.'
    log_info "The complete log has been saved to ${log_file}."
    log_info 'To manage the installed home environment, use the "home-env" command.'

    # Clean up
    clean_up

    # Reload the shell
    prompt_for_continue 'About to reload the shell.'
    echo
    is_true can_sudo && exec sudo -i -u "${USER}" bash -c "cd '${PWD}'; exec '$(command -v zsh)' -l" 2>/dev/null || exec "$(command -v zsh)" -l 2>/dev/null
}

# Run main logic
main "$@"
