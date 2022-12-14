#!/usr/bin/env bash
#
# Automate home environment setup.

# Unofficial bash strict mode
set -euo pipefail

#################################
# Constants
#################################

# Repo
repo=https://github.com/raymond-u/dotfiles.git
version='0.3.7'

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
gitconfig=src/git/config
gitignore=src/git/ignore
htoprc=src/htop/htoprc
hushlogin=src/misc/.hushlogin
nix_env=src/nix/env.nix
p10k=src/powerlevel10k/p10k.zsh
passage_archive=src/passage/archive.age
ssh_archive=src/ssh/archive.age
taskrc=src/taskwarrior/taskrc
wezterm=src/wezterm/wezterm.lua
wgetrc=src/wget/wgetrc
zshenv=src/zsh/.zshenv
zshrc=src/zsh/.zshrc

# Package list
brew_pkgs=(
    '# Shells'
    '  bash'
    '  zsh'
    ''
    '# System commands'
    '  coreutils'
    '  findutils'
    '  gawk'
    '  gnu-getopt'
    '  gnu-sed'
    '  less'
    ''
    '# General commands'
    '  bat'
    '  exa'
    '  fd'
    '  fzf'
    '  hexyl'
    '  ripgrep'
    '  tree'
    '  zoxide'
    ''
    '# System utilities'
    '  bottom'
    '  duf'
    '  htop'
    '  ncdu'
    '  neofetch'
    '  procs'
    ''
    '# General utilities'
    '  age'
    '  direnv'
    '  hyperfine'
    '  pandoc'
    '  rename'
    '  task'
    '  tealdeer'
    '  thefuck'
    ''
    '# Media viewers'
    '  chafa'
    ''
    '# Text editors'
    '  nano'
    '  neovim'
    '  vim'
    ''
    '# Web'
    '  aria2'
    '  httpie'
    '  openssh'
    '  qrcp'
    '  wget'
    ''
    '# Languages'
    '  dotnet'
    '  node'
    '  openjdk'
    '  python'
    '  r'
    '  rust'
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
    ''
    '# Media viewers'
    '  iina'
    '  xnviewmp'
    ''
    '# Productivity'
    '  raycast'
    ''
    '# Terminal'
    '  wezterm'
    ''
    '# Utilities'
    '  aldente'
    '  keka'
    '  xnconvert'
    ''
    '# Web browser'
    '  google-chrome'
)
nix_pkgs=(
    '# Shells'
    '  bash'
    '  zsh'
    ''
    '# Terminal multiplexer'
    '  wezterm'
    ''
    '# System commands'
    '  coreutils'
    '  findutils'
    '  gawk'
    '  gnu-sed'
    '  less'
    ''
    '# General commands'
    '  bat'
    '  exa'
    '  fd'
    '  fzf'
    '  hexyl'
    '  ripgrep'
    '  tree'
    '  zoxide'
    ''
    '# System utilities'
    '  bottom'
    '  duf'
    '  htop'
    '  ncdu'
    '  neofetch'
    '  procs'
    ''
    '# General utilities'
    '  age'
    '  direnv'
    '  hyperfine'
    '  p7zip'
    '  pandoc'
    '  rename'
    '  taskwarrior'
    '  tealdeer'
    '  thefuck'
    '  unrar'
    ''
    '# Media viewers'
    '  chafa'
    ''
    '# Text editors'
    '  nano'
    '  neovim'
    '  vim'
    ''
    '# Web'
    '  aria2'
    '  curl'
    '  httpie'
    '  openssh'
    '  qrcp'
    '  wget'
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

config_flags=(
    'is_linux'
    'is_macos'
    'is_macos_arm64'
    'can_sudo'
    'has_identity'
    'install_cask'
    'use_mirror'
)

# Config settings
identity_file=
passphrase=

# Misc
reminders=()

#################################
# Functions
#################################

print_help() {
    echo 'Usage:'
    echo '  install.sh [<options>]'
    echo '  Automate home environment setup.'
    echo
    echo 'Supported platforms:'
    echo '  Linux'
    echo '  macOS (including arm64 version)'
    echo
    echo 'Options:'
    echo '  -h, --help              Show help, then exit.'
    echo '  -v, --version           Show version, then exit.'
    echo '  -u, --update            Update home environment.'
    echo '  -n, --dry-run           Print info, but do not change anything.'
    echo '  --is-linux              Force the script to identify the OS as Linux.'
    echo '  --is-macos              Force the script to identify the OS as macOS.'
    echo '  --is-macos-arm64        Force the script to identify the OS as macOS arm64.'
    echo '  --can-sudo              Use sudo when needed.'
    echo '  --has-identity          Can use the identity file to decrypt secrets.'
    echo '  --identity-file         Specify the identity file.'
    echo '  --install-cask          Install GUI applications for macOS.'
    echo '  --use-mirror            Use USTC mirrors.'
}

print_welcome() {
    if is_true update; then
        log_info 'Update home environment...'
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
    echo "Welcome! This script will install Raymond's home environment on your machine."
    
    if is_true dry_run; then
        echo 'We are in dry run mode. Nothing will be changed.'
    else
        echo 'It has a dry run mode "-n/--dry-run", in case you are afraid of breaking things.'
    fi
    
    echo
    
    if is_true is_linux; then
        echo 'Linux detected. Nix will be used as the universal package manager.'
    elif is_true is_macos_arm64; then
        echo 'macOS arm64 detected. Homebrew will be used as the package manager.'
    elif is_true is_macos; then
        echo 'macOS detected. Homebrew will be used as the package manager.'
    fi
    
    echo "A full-fledged shell setup, common packages, and some tweaks will be installed.${no_color}"
    
    prompt_continue 'Ready?'
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

prompt_continue() {
    local key
    
    while true; do
        read -rp $'\n'"${yellow}$1 Press any key to continue. >${no_color}" -n1 key
        
        case "${key}" in
            *) break ;;
        esac
    done
    
    echo
}

prompt_passphrase() {
    read -srp $'\n'"${yellow}$1 >${no_color}" "$2"
    
    echo
}

prompt_string() {
    read -rp $'\n'"${yellow}$1 >${no_color}" "$2"
}

prompt_yesno() {
    local yesno="$([[ "$2" == 'y' ]] && echo '(Y/n)' || echo '(y/N)')"
    
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

put_dotfile() {
    log_info "Put $1 dotfile to $3."
    if ! is_dry_run; then
        if [[ -f "$3" ]]; then
            if ! is_true update; then
                log_info "$1 dotfile already exists. Rename it to $3.old."
                reminders+=("$1: Old dotfile lingers in $3.old.")
                mv "$3" "$3.old"
            fi
        else
            mkdir -p "$(dirname "$3")"
        fi
        
        cp "$(preprocess_file "$2")" "$3"
    fi
}

clean_up() {
    log_info 'Clean up...'
    while popd &>/dev/null; do :; done
    rm -rf "${tmpdir}"
    exec 1>&3 2>&4 3>&- 4>&-
    
    trap ERR INT TERM
}

#################################
# Main
#################################

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
            log_error "Error: Unknown flag \"$1\"."
            print_help
            exit 0
            ;;
        *)
            if [[ ! "${config_flags[*]}" =~ "$1" ]]; then
                log_error "Error: Unknown flag \"$1\"."
                exit 0
            fi
            declare -g "$1"=true
            shift
            ;;
    esac
done

# Quit if OS is specified more than once
if (( os_flags_counter > 1 )); then
    log_error 'Error: OS flags should be specified exactly once, if set.'
    log_error 'Choose the one that best describes the OS.'
    exit 0
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
        log_error 'Error: Unknown architecture.'
        log_error 'Supported platforms:'
        log_error '  aarch64'
        log_error '  x86_64'
        exit 0
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
            log_error 'Error: Unknown OS.'
            log_error 'Supported platforms:'
            log_error '  Linux'
            log_error '  macOS (including arm64 version)'
            log_error
            log_error 'The script can be forced to fall into one of these by passing specific arguments. Run with "-h/--help" for more information.'
            exit 0
            ;;
    esac
fi

# Check the identity file
if is_true identity_file; then
    if [[ ! -f "${identity_file}" ]]; then
        log_error 'Error: The identity file does not exist.'
        exit 0
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
        log_error "Error: \"${_program}\" does not exist."
        exit 0
    fi
done
unset _prerequisites
unset _program

# Redirect output
log_file="$(is_true update && echo "${PWD}/update.log" || echo "${PWD}/install.log")"
exec 3>&1 4>&2 &> >(tee "${log_file}")

# Create temporary directory
tmpdir="$(mktemp -d 2>/dev/null || mktemp -d -t 'tmp')"

# Intercept signals
trap 'clean_up; exit 1' ERR INT TERM

# Print welcome messages
print_welcome

# Prompt for use of sudo
is_true can_sudo || prompt_yesno 'Can we use sudo?' 'y' can_sudo

# Propmt for use of mirrors
is_true use_mirror || prompt_yesno 'Do you wish to use USTC mirrors?' 'n' use_mirror

# Clone dotfiles into temp directory
log_info 'Clone repo into a temporary directory...'
git clone --depth=1 --quiet "${repo}" "${tmpdir}/dotfiles"
pushd "${tmpdir}/dotfiles" >/dev/null

# Configure for Linux
if is_true is_linux; then
    # Create empty folders
    log_info 'Create empty folders in the home directory...'
    is_dry_run || mkdir -p "${HOME}/"{bin,downloads,opt,playground} "${HOME}/.local/state/"{less,zsh}
    
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
                    _nix_installation="$(selinuxenabled 2>/dev/null && echo 'single-user' || echo 'multi-user')"
                else
                    # Check if OS supports user namespaces for unprivileged users
                    if [[ "$(unshare --user --pid echo 'YES' 2>/dev/null)" == 'YES' ]]; then
                        _nix_installation='nix-user-chroot'
                    else
                        _nix_installation='proot'
                    fi
                fi
            fi
            case "${_nix_installation}" in
                multi-user)
                    log_info 'Install Nix in multi-user mode...'
                    if ! is_dry_run; then
                        sh <(curl -L https://nixos.org/nix/install) --daemon
                        source /etc/profile.d/nix.sh
                    fi
                    ;;
                single-user)
                    log_info 'Install Nix in single-user mode...'
                    if ! is_dry_run; then
                        sh <(curl -L https://nixos.org/nix/install) --no-daemon
                        source /etc/profile.d/nix.sh
                    fi
                    ;;
                nix-user-chroot)
                    log_info 'Install Nix in non-root mode using nix-user-chroot...'
                    curl -L "https://github.com/nix-community/nix-user-chroot/releases/download/1.2.2/nix-user-chroot-bin-1.2.2-${architecture}-unknown-linux-musl" >"${tmpdir}/nix-user-chroot"
                    chmod +x "${tmpdir}/nix-user-chroot"
                    if ! is_dry_run; then
                        mkdir -p "${HOME}/.nix"
                        "${tmpdir}/nix-user-chroot" "${HOME}/.nix" bash -c 'curl -L https://nixos.org/nix/install | sh'
                        "${tmpdir}/nix-user-chroot" "${HOME}/.nix" bash -c "nix-env -i -f '${tmpdir}/dotfiles/${nix_env}'"
                        mv "${tmpdir}/nix-user-chroot" "${HOME}/bin"
                    fi
                    reminders+=("nix-user-chroot: The binary has been installed to ${HOME}/bin.")
                    reminders+=('nix-user-chroot: Note that you can only use Nix and the installed packages within the shell started by "nix-user-chroot ~/.nix bash".')
                    ;;
                proot)
                    log_info 'Install Nix in non-root mode using proot...'
                    curl -L "https://github.com/proot-me/proot/releases/download/v5.3.0/proot-v5.3.0-${architecture}-static" >"${tmpdir}/proot"
                    chmod +x "${tmpdir}/proot"
                    log_info 'A shell will be spawned by PRoot. Please enter "curl -L https://nixos.org/nix/install | sh" in the new shell to install Nix.'
                    log_info "After Nix installation is finished, please continue to enter \"nix-env -i -f '${tmpdir}/dotfiles/${nix_env}'\" to set up home environment."
                    log_info "When done, please enter exit to get back."
                    if ! is_dry_run; then
                        mkdir -p "${HOME}/.nix"
                        mkdir -p "${HOME}/.config/nix"
                        echo 'sandbox = false' >>"${HOME}/.config/nix/nix.conf"
                        "${tmpdir}/proot" -b "${HOME}/.nix:/nix"
                        mv "${tmpdir}/proot" "${HOME}/bin"
                    fi
                    reminders+=("PRoot: The binary has been installed to ${HOME}/bin.")
                    reminders+=('PRoot: Note that you can only use Nix and the installed packages within the shell started by "proot -b ~/.nix:/nix".')
                    ;;
            esac
            unset _nix_installation
        fi
        
        # Use mirror for Nix
        if is_true use_mirror; then
            _can_use_mirror=true
            if [[ ! -f /etc/nix/nix.conf || ! "$(</etc/nix/nix.conf)" =~ 'https://mirrors.ustc.edu.cn/nix-channels/store' ]]; then
                if is_true can_sudo; then
                    log_info 'Add USTC mirror as a trusted substituter.'
                    is_dry_run || sudo bash -c 'mkdir -p /etc/nix; echo "trusted-substituters = https://mirrors.ustc.edu.cn/nix-channels/store" >>/etc/nix/nix.conf'
                else
                    log_error 'Warning: USTC mirror is not a trusted substituter. Sudo is needed to add it to /etc/nix/nix.conf.'
                    log_error 'Abort setting mirror for Nix.'
                    _can_use_mirror=false
                fi
            fi
            if is_true _can_use_mirror; then
                log_info 'Use USTC mirror for Nix.'
                if ! is_dry_run; then
                    if [[ -n "$(command -v nix-channel)" ]]; then
                        nix-channel --add https://mirrors.ustc.edu.cn/nix-channels/nixpkgs-unstable nixpkgs
                    fi
                    mkdir -p "${HOME}/.config/nix"
                    echo 'substituters = https://mirrors.ustc.edu.cn/nix-channels/store https://cache.nixos.org/' >>"${HOME}/.config/nix/nix.conf"
                    ! is_true can_sudo || sudo systemctl restart nix-daemon
                fi
            fi
            unset _can_use_mirror
        fi
    fi
    
    # Install from Nix
    if [[ -n "$(command -v nix-env)" ]]; then
        log_section 'Nix Packages'
        log_info "$(get_package_list)" yellow
        
        # Prompt for confirmation of package installation
        prompt_continue 'About to install the above packages from Nix.'
        log_info 'Install packages...'
        if ! is_dry_run; then
            if [[ ! -f "${HOME}/.config/nixpkgs/config.nix" || ! "$(<"${HOME}/.config/nixpkgs/config.nix")" =~ '{ allowUnfree = true; }' ]]; then
                mkdir -p "${HOME}/.config/nixpkgs"
                echo '{ allowUnfree = true; }' >>"${HOME}/.config/nixpkgs/config.nix"
            fi
            nix-channel --update
            nix-env -i -f "${nix_env}"
        fi
    fi
    
    # Configure Zsh
    if ! is_true update; then
        log_section 'Zsh Configuration'
        
        # Install Zinit
        log_info 'Install Zinit...'
        is_dry_run || NO_EDIT=1 NO_TUTORIAL=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
        reminders+=('Zinit: Zinit will self-update when the shell reloads.')
        reminders+=('Zinit: You can run "zinit self-update" to compile Zinit (optional).')
        
        # Change the login shell to Zsh
        if [[ ! "${SHELL}" =~ 'zsh'$ ]]; then
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
    
    # Configure tealdeer
    log_info 'Fetch caches for tealdeer.'
    is_dry_run || tldr -u
    
    # Configure Neovim
    if ! is_true update; then
        log_section 'Neovim Configuration'
        _yesno=true
        
        # Check if config files already exist
        if [[ -n "$(ls -A "${HOME}/.config/nvim" 2>/dev/null)" ]]; then
            prompt_yesno 'Neovim config files already exist. Do you wish to remove them and install NvChad?' 'n' _yesno
        fi
        
        # Install NvChad
        if is_true _yesno; then
            if ! is_dry_run; then
                rm -rf "${HOME}/.config/nvim" "${HOME}/.local/share/nvim"
                git clone --depth=1 --quiet https://github.com/NvChad/NvChad "${HOME}/.config/nvim"
            fi
            reminders+=('Neovim: Neovim will self-update when it is launched for the first time.')
        fi
        unset _yesno
    fi
    
    # Configure Conda
    if ! is_true update; then
        log_section 'Conda Configuration'
        
        # Use mirror for Conda
        if is_true use_mirror; then
            log_info 'Use USTC mirror for Conda.'
            is_dry_run || cat >"${HOME}/.condarc" <<'EOF'
channels:
  - https://mirrors.ustc.edu.cn/anaconda/cloud/menpo/
  - https://mirrors.ustc.edu.cn/anaconda/cloud/bioconda/
  - https://mirrors.ustc.edu.cn/anaconda/cloud/msys2/
  - https://mirrors.ustc.edu.cn/anaconda/cloud/conda-forge/
  - https://mirrors.ustc.edu.cn/anaconda/pkgs/main/
  - https://mirrors.ustc.edu.cn/anaconda/pkgs/free/
  - defaults
show_channel_urls: true
EOF
        fi
        
        # Install Conda
        log_info 'Install Conda...'
        is_dry_run || curl -fsSL https://repo.anaconda.com/miniconda/Miniconda3-py39_4.12.0-Linux-x86_64.sh | sh -s -- -b -p "${HOME}/opt/miniconda3"
        
        # Install Mamba
        log_info 'Install Mamba...'
        if ! is_dry_run; then
            eval "$("${HOME}/opt/miniconda3/bin/conda" shell.zsh hook)"
            conda install mamba -n base -c conda-forge -y
        fi
        
        # Install Snakemake
        log_info 'Install Snakemake...'
        is_dry_run || mamba create -n snakemake -c conda-forge -c bioconda -y snakemake
    fi
    
    # Configure Rust
    if ! is_true update; then
        log_section 'Rust Configuration'
        
        # Connecting to crates is fast enough, so no need to use mirror
        if is_true use_mirror; then
            log_info 'Rust does not need to use mirror.'
        fi
        
        # Install Rust
        log_info 'Install Rust...'
        if ! is_dry_run; then
            curl -fsSL https://sh.rustup.rs | RUSTUP_HOME="${HOME}/opt/rustup" sh -s -- -y --no-modify-path
            source "${HOME}/.cargo/env"
            rustup default stable
        fi
        
        # Install rust-script
        log_info 'Install rust-script...'
        is_dry_run || cargo install rust-script
    fi
    
    # Set up dotfiles beforehand
    log_section 'Dotfiles Setup'
    put_dotfile 'Aria2' "${aria2}" "${HOME}/.config/aria2/aria2.conf"
    put_dotfile 'bottom' "${bottom}" "${HOME}/.config/bottom/bottom.toml"
    put_dotfile 'direnv' "${direnvrc}" "${HOME}/.config/direnv/direnvrc"
    put_dotfile 'Git' "${gitconfig}" "${HOME}/.config/git/config"
    put_dotfile 'Git' "${gitignore}" "${HOME}/.config/git/ignore"
    put_dotfile 'htop' "${htoprc}" "${HOME}/.config/htop/htoprc"
    put_dotfile 'login' "${hushlogin}" "${HOME}/.hushlogin"
    put_dotfile 'Powerlevel10k' "${p10k}" "${HOME}/.config/powerlevel10k/p10k.zsh"
    put_dotfile 'Taskwarrior' "${taskrc}" "${HOME}/.config/task/taskrc"
    put_dotfile 'Wget' "${wgetrc}" "${HOME}/.config/wget/wgetrc"
    put_dotfile 'Zsh' "${zshrc}" "${HOME}/.zshrc"
    put_dotfile 'Zsh' "${zshenv}" "${HOME}/.zshenv"
    
    # Reminders for Linux
    reminders+=('')
    source "$(preprocess_file "${linux_reminders}")"

# Configure for macOS
elif is_true is_macos; then
    # Create empty folders
    log_info 'Create empty folders in the home directory...'
    is_dry_run || mkdir -p "${HOME}/.local/"{bin,opt} "${HOME}/Playground" "${HOME}/Projects/"{pycharm,visual_studio_code} "${HOME}/.local/state/"{less,zsh}
    
    # Prompt for the identity file
    is_true has_identity || prompt_yesno 'Do you have the identity file? (Choose no if you have no idea what it is.)' 'n' has_identity
    if is_true has_identity && ! is_true identity_file; then
        if [[ -f "${HOME}/.passage/identities" ]]; then
            prompt_continue "Use the identity file located at ${HOME}/.passage/identities."
            identity_file="${HOME}/.passage/identities"
        else
            prompt_string 'Please enter the path to the identity file.' identity_file
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
    ! is_true has_identity || prompt_passphrase "Please enter the passphrase of the identity file. (If there isn't one, just hit enter.)" passphrase
    
    # Configure macOS
    if ! is_true update; then
        log_section 'macOS Configuration'
        log_info 'Configure general UI/UX...'
        log_info 'Configure trackpad, mouse and keyboard...'
        log_info 'Configure energy saving...'
        log_info 'Configure screen...'
        log_info 'Configure bluetooth accessories...'
        log_info 'Configure Disk Utility...'
        log_info 'Configure Dock, Dashboard and Mission Control...'
        log_info 'Configure Finder...'
        log_info 'Configure Mac App Store...'
        log_info 'Configure Mail...'
        log_info 'Configure Photos...'
        log_info 'Configure Safari...'
        log_info 'Configure Terminal...'
        log_info 'Configure TextEdit...'
        log_info 'Configure Time Machine...'
        is_dry_run || bash "${set_defaults}"
    fi
    
    # Configure Homebrew
    if ! is_true update; then
        log_section 'Homebrew Configuration'
        
        # Use mirror for Homebrew
        if is_true use_mirror; then
            log_info 'Use USTC mirror for Homebrew.'
            export HOMEBREW_BREW_GIT_REMOTE=https://mirrors.ustc.edu.cn/brew.git
            export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.ustc.edu.cn/homebrew-bottles
            export HOMEBREW_CORE_GIT_REMOTE=https://mirrors.ustc.edu.cn/homebrew-core.git
        fi
        
        # Install Homebrew
        log_info 'Install Homebrew...'
        is_dry_run || bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # One extra step required for Apple Silicon machines
        if is_true is_macos_arm64; then
            is_dry_run || eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        
        # Install command-not-found
        log_info 'Install Homebrew command-not-found...'
        is_dry_run || brew command-not-found-init
    fi
    
    # Prompt for installation of GUI applications
    log_section 'Homebrew Packges'
    { is_true install_cask && ! is_true update; } || prompt_yesno 'Do you wish to install GUI applications from Homebrew Cask?' 'y' install_cask
    
    # Prompt for confirmation of package installation
    log_info "$(get_package_list)" yellow
    prompt_continue 'About to install the above packages from Homebrew.'
    
    # Install from Homebrew
    log_info 'Install packages...'
    if ! is_dry_run; then
        ! is_true use_mirror || brew tap --custom-remote --force-auto-update homebrew/cask https://mirrors.ustc.edu.cn/homebrew-cask.git
        brew bundle --file="$(preprocess_file "${brewfile}")"
        
        # Configure openjdk
        sudo ln -sfn "$(brew --prefix)/opt/openjdk/libexec/openjdk.jdk" /Library/Java/JavaVirtualMachines/openjdk.jdk
    fi
    
    # Configure Zsh
    if ! is_true update; then
        log_section 'Zsh Configuration'
        
        # Install Zinit
        log_info 'Install Zinit...'
        is_dry_run || NO_EDIT=1 NO_TUTORIAL=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
        reminders+=('Zinit: Zinit will self-update when the shell reloads.')
        reminders+=('Zinit: You can run "zinit self-update" to compile Zinit (optional).')
        
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
    
    # Configure tealdeer
    log_info 'Fetch caches for tealdeer.'
    is_dry_run || tldr -u
    
    # Configure Neovim
    if ! is_true update; then
        log_section 'Neovim Configuration'
        _yesno=true
        
        # Check if config files already exist
        if [[ -n "$(ls -A "${HOME}/.config/nvim" 2>/dev/null)" ]]; then
            prompt_yesno 'Neovim config files already exist. Do you wish to remove them and install NvChad?' 'n' _yesno
        fi
        
        # Install NvChad
        if is_true _yesno; then
            if ! is_dry_run; then
                rm -rf "${HOME}/.config/nvim" "${HOME}/.local/share/nvim"
                git clone --depth=1 --quiet https://github.com/NvChad/NvChad "${HOME}/.config/nvim"
            fi
            reminders+=('Neovim: Neovim will self-update when it is launched for the first time.')
        fi
        unset _yesno
    fi
    
    # Configure passage
    if is_true has_identity; then
        log_section 'Passage Setup'
        
        # Install passage
        if ! is_true update; then
            log_info 'Install passage...'
            git clone --depth=1 --quiet https://github.com/FiloSottile/passage "${tmpdir}/passage"
            if ! is_dry_run; then
                pushd "${tmpdir}/passage" >/dev/null
                make "PREFIX=${HOME}/.local/opt/passage" install
                ln -sf "${HOME}/.local/opt/passage/bin/passage" "${HOME}/.local/bin"
                popd >/dev/null
            fi
        fi
        
        # Set up passage store
        log_info "Extract passage store to ${HOME}/.passage/store..."
        is_dry_run || bash "${crypto}" -p "$(command -v age)" -d -i "${identity_file}" <<<"$(<"${passage_archive}") ${passphrase}" | base64 -d | tar -xzC "${HOME}/.passage"
        
        # Move the identity file
        if [[ "${identity_file}" != "${HOME}/.passage/identities" ]]; then
            prompt_yesno "Do you wish to move the identity file to ${HOME}/.passage/identities?" 'y' _yesno
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
    put_dotfile 'Aria2' "${aria2}" "${HOME}/.config/aria2/aria2.conf"
    put_dotfile 'bottom' "${bottom}" "${HOME}/.config/bottom/bottom.toml"
    put_dotfile 'direnv' "${direnvrc}" "${HOME}/.config/direnv/direnvrc"
    put_dotfile 'Git' "${gitconfig}" "${HOME}/.config/git/config"
    put_dotfile 'Git' "${gitignore}" "${HOME}/.config/git/ignore"
    put_dotfile 'htop' "${htoprc}" "${HOME}/.config/htop/htoprc"
    put_dotfile 'login' "${hushlogin}" "${HOME}/.hushlogin"
    put_dotfile 'Powerlevel10k' "${p10k}" "${HOME}/.config/powerlevel10k/p10k.zsh"
    put_dotfile 'Taskwarrior' "${taskrc}" "${HOME}/.config/task/taskrc"
    put_dotfile 'WezTerm' "${wezterm}" "${HOME}/.config/wezterm/wezterm.lua"
    put_dotfile 'Wget' "${wgetrc}" "${HOME}/.config/wget/wgetrc"
    put_dotfile 'Zsh' "${zshrc}" "${HOME}/.zshrc"
    put_dotfile 'Zsh' "${zshenv}" "${HOME}/.zshenv"
    
    # Only if the identity file is present
    if is_true has_identity; then
        # Set up SSH
        log_info "Put SSH dotfiles to ${HOME}/.ssh."
        is_dry_run || bash "${crypto}" -p "$(command -v age)" -d -i "${identity_file}" <<<"$(<"${ssh_archive}") ${passphrase}" | base64 -d | tar -xzC "${HOME}"
        
        # Set up Clash
        log_info "Put Clash dotfiles to ${HOME}/.config/clash."
        is_dry_run || bash "${crypto}" -p "$(command -v age)" -d -i "${identity_file}" <<<"$(<"${clash_archive}") ${passphrase}" | base64 -d | tar -xzC "${HOME}/.config"
        
        # Reminders for macOS
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
log_info "Complete log has been saved to ${log_file}."
log_info 'You can use "home-env" command to keep home environment up-to-date.'

# Clean up
clean_up

# Reload the shell
prompt_continue 'About to reload the shell.'
echo
is_true can_sudo && exec sudo -i -u "${USER}" bash -c "cd '${PWD}'; exec '$(command -v zsh)' -l" || exec "$(command -v zsh)" -l
