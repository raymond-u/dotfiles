#!/usr/bin/env bash
#
# Encrypt or decrypt strings, using key files. Read passphrase from stdin if possible.
#
# A passphrase can be followed after the input data, with a space present as the delimiter.
# Encrypt: encrypt with age -> encode with base64
# Decrypt: decode with base64 -> decrypt with age
#
# Caveat: would output "age: error: ..." to stdout instead of stderr

# Unofficial bash strict mode
set -euo pipefail

#################################
# Functions
#################################

print_help() {
    echo 'Usage:'
    echo '  crypto.sh [options...] -p path [-r string] [-i path]'
    echo '  Encrypt or decrypt strings using key files.'
    echo
    echo 'Options:'
    echo '  -h, --help              Show help message and exit.'
    echo '  -p, --path              Set the path to the age binary.'
    echo '  -e, --encrypt           Encrypt input and write to output (default).'
    echo '  -r, --recipient         Specify recipient for encryption.'
    echo '  -d, --decrypt           Decrypt input and write to output.'
    echo '  -i, --identity          Set the identity file for decryption.'
    echo
    echo 'A passphrase can follow the input data, separated by a space.'
    echo 'Encryption: Encrypt with age -> Encode using Base64'
    echo 'Decryption: Decode using Base64 -> Decrypt with age'
}

#################################
# Main
#################################

# Parse arguments
path=
decrypt=false
encrypt=true
recipient=
identity=
while (( $# > 0 )); do
    case "$1" in
        -h|--help)
            print_help
            exit 0
            ;;
        -p|--path)
            path="$2"
            shift
            shift
            ;;
        -e|--encrypt)
            decrypt=false
            encrypt=true
            shift
            ;;
        -r|--recipient)
            recipient="$2"
            shift
            shift
            ;;
        -d|--decrypt)
            decrypt=true
            encrypt=false
            shift
            ;;
        -i|--identity)
            identity="$2"
            shift
            shift
            ;;
        *)
            echo "Error: unknown flag \"$1\"." >&2
            print_help
            exit 0
            ;;
    esac
done

# Check if age exists and is executable
if [[ ! -x "${path}" ]]; then
    echo 'Error: age does not exist or is not executable.' >&2
    exit 0
fi

# Encrypt
if [[ "${encrypt}" == true ]]; then
    # Read string from stdin
    string="$(cat)"

    # Check if the recipient is valid
    if [[ ! "${recipient}" =~ ^'age1' ]]; then
        echo 'Error: the recipient is not valid. It must start with "age1".' >&2
        exit 0
    fi

    "${path}" -r "${recipient}" <<<"${string}" | base64 | tr -d '\n'
fi

# Decrypt
if [[ "${decrypt}" == true ]]; then
    # Read string and passphrase from stdin
    read -ra data
    string="${data[0]}"
    passphrase="${data[@]:1}"

    # Check if the identity file exists
    if [[ ! -f "${identity}" ]]; then
        echo 'Error: the identity file does not exist.' >&2
        exit 0
    fi

    # Create temp files for use of expect
    tmpdir="$(mktemp -d 2>/dev/null || mktemp -d -t 'tmp')"
    cat >"${tmpdir}/age_script" <<EOF
base64 -d <<<'${string}' | '${path}' -d -i '${identity}'
EOF
    cat >"${tmpdir}/age_helper" <<'EOF'
log_user 0
set timeout 2
set passphrase [gets stdin]

eval spawn bash "$argv"
expect "Enter passphrase"
send -- "$passphrase\r"

log_user 1
expect eof
EOF

    # Automate decryption
    expect -f "${tmpdir}/age_helper" "${tmpdir}/age_script" <<<"${passphrase}" | perl -0777 -pe 's/^[\n\r]*(.*?)[\n\r]*$/\1/s' | perl -pe 's/(\x9B|\x1B\[)[0-?]*[ -\/]*[@-~]//g'
    rm -rf "${tmpdir}"
fi
