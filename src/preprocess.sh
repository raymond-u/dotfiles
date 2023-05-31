#!/usr/bin/env bash
#
# Transform files based on custom rules and flags.
#
# The script accepts flags, values, and other arguments, transforming files based on the following rules (rules can be nested):
# 1. Keep lines between
#    # [ FOO start ]
#    # [ FOO end ]
#    if FOO is a flag; otherwise, remove.
# 2. Keep lines between
#    # [ ! FOO start ]
#    # [ ! FOO end ]
#    if FOO is not a flag; otherwise, remove.
# 3. Decrypt and replace string xxxxxx
#    # [ ? age ] base64=xxxxxx
#    if an identity file is present; otherwise, remove.
# 4. Assign the value of BAZ to a local variable BAR.
#    # [ @ BAR=BAZ ]

# Unofficial bash strict mode
set -euo pipefail

#################################
# Functions
#################################

print_help() {
    echo 'Usage:'
    echo '  preprocess.sh -i input_path -o output_path [options...] [values...] [flags...]'
    echo '  Transform files based on custom rules and flags.'
    echo
    echo 'Options:'
    echo '  -h        Show help message and exit.'
    echo '  -i        Set the input file path.'
    echo '  -o        Set the output file path.'
    echo '  -s        Set the path to crypto.sh.'
    echo '  -p        Set the path to the age binary.'
    echo '  -f        Set the identity file path.'
    echo
    echo 'The script accepts flags, values, and other arguments, transforming files based on the following rules (rules can be nested):'
    echo '1. Keep lines between'
    echo '   # [ foo start ]'
    echo '   # [ foo end ]'
    echo '   if FOO is a flag; otherwise, remove.'
    echo '2. Keep lines between'
    echo '   # [ ! foo start ]'
    echo '   # [ ! foo end ]'
    echo '   if FOO is not a flag; otherwise, remove.'
    echo '3. Decrypt and replace string xxxxxx'
    echo '   # [ ? age ] base64=xxxxxx'
    echo '   if an identity file is present; otherwise, remove.'
    echo '4. Assign the value of BAZ to a local variable BAR.'
    echo '   # [ @ BAR=BAZ ]'
}

#################################
# Main
#################################

# Parse arguments
_input=
_output=
_script=
_path=
_identity=
while (( $# > 0 )); do
    case "$1" in
        -h)
            print_help
            exit 0
            ;;
        -i)
            _input="$2"
            shift
            shift
            ;;
        -o)
            _output="$2"
            shift
            shift
            ;;
        -s)
            _script="$2"
            shift
            shift
            ;;
        -p)
            _path="$2"
            shift
            shift
            ;;
        -f)
            _identity="$2"
            shift
            shift
            ;;
        --*)
            [[ "$1" =~ --(.*) ]] && declare -g "${BASH_REMATCH[1]}"="$2"
            shift
            shift
            ;;
        *)
            declare -g "$1"=true
            shift
            ;;
    esac
done

# Read passphrase from stdin
_passphrase=
if [[ -n "${_script}" ]] && [[ -n "${_path}" ]] && [[ -n "${_identity}" ]]; then
    read -r _passphrase
fi

# Check if input and output have values
if [[ -z "${_input}" ]] || [[ -z "${_output}" ]]; then
    echo 'Error: input and output must be specified.' >&2
    exit 1
fi

# Get contents of the input file
if [[ ! -f "${_input}" ]]; then
    echo 'Error: the input file does not exist.' >&2
    exit 1
fi
_file_string="$(<"${_input}")"

# Transforms macro # [ FOO start ]
_flags_set="$(perl -nle 'print $1 if(/^ *(?:-- )?# \[ (?!! )(.*) start \]$/)' <<<"${_file_string}")"
for _flag in ${_flags_set}; do
    if [[ -n "${!_flag+_}" ]]; then
        _file_string="$(perl -0777 -pse 's/^ *(?:-- )?# \[ \Q$flag\E start \]$\\n(.*?)^ *(?:-- )?# \[ \Q$flag\E end \]$\\n/\1/ms' -- -flag="${_flag}" <<<"${_file_string}")"
    else
        _file_string="$(perl -0777 -pse 's/^ *(?:-- )?# \[ \Q$flag\E start \]$\\n.*?^ *(?:-- )?# \[ \Q$flag\E end \]$\\n//ms' -- -flag="${_flag}" <<<"${_file_string}")"
    fi
done

# Transforms macro # [ ! FOO start ]
_flags_not_set="$(perl -nle 'print $1 if(/^ *(?:-- )?# \[ ! (.*) start \]$/)' <<<"${_file_string}")"
for _flag in ${_flags_not_set}; do
    if [[ -z "${!_flag+_}" ]]; then
        _file_string="$(perl -0777 -pse 's/^ *(?:-- )?# \[ ! \Q$flag\E start \]$\\n(.*?)^ *(?:-- )?# \[ ! \Q$flag\E end \]$\\n/\1/ms' -- -flag="${_flag}" <<<"${_file_string}")"
    else
        _file_string="$(perl -0777 -pse 's/^ *(?:-- )?# \[ ! \Q$flag\E start \]$\\n.*?^ *(?:-- )?# \[ ! \Q$flag\E end \]$\\n//ms' -- -flag="${_flag}" <<<"${_file_string}")"
    fi
done

# Transforms macro # [ ? age ] base64=
if [[ -n "${_script}" ]] && [[ -n "${_path}" ]] && [[ -n "${_identity}" ]]; then
    _encrypted_strings="$(perl -nle 'print $1 if (/^ *(?:-- )?# \[ \? age \] base64=(.*)$/)' <<<"${_file_string}")"
    for _encrypted in ${_encrypted_strings}; do
        _decrypted="$(bash "${_script}" -p "${_path}" -d -i "${_identity}" <<<"${_encrypted} ${_passphrase}")"

        if [[ "${_decrypted}" =~ 'age: error: ' ]]; then
            echo "${_decrypted}" >&2
            exit 1
        fi

        _file_string="$(perl -0777 -pse 's/^ *(?:-- )?# \[ \? age \] base64=\Q$old\E$/$new/m' -- -old="${_encrypted}" -new="${_decrypted}" <<<"${_file_string}")"
    done
else
    _file_string="$(perl -0777 -pe 's/^ *(?:-- )?# \[ \? age \] base64=.*$\\n//gm' <<<"${_file_string}")"
fi

# Transforms macro # [ @ BAR=BAZ ]
_pairs="$(perl -nle 'print $1 if(/^ *(?:-- )?# \[ @ ([a-zA-Z_0-9]*=[a-zA-Z_0-9]*) \]$/)' <<<"${_file_string}")"
for _pair in ${_pairs}; do
    [[ "$_pair" =~ ([a-zA-Z_0-9]*)=([a-zA-Z_0-9]*) ]] && _name="${BASH_REMATCH[1]}" && _value="${BASH_REMATCH[2]}"
    if [[ -z "${!_value+_}" ]]; then
        echo "Error: the value of ${_value} is unknown." >&2
        exit 1
    else
        _file_string="$(perl -0777 -pse 's/^( *)(?:-- )?# \[ @ \Q$old\E \]$/\1$new/m' -- -old="${_pair}" -new="${_name}='${!_value}'" <<<"${_file_string}")"
    fi
done

# Strip consecutive empty lines
_file_string="$(perl -ple 's/^\s+$//' <<<"${_file_string}" | perl -00 -pe0)"

# Save to the output file
printf '%s' "${_file_string}" >"${_output}"
