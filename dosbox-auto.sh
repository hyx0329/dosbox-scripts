#!/bin/bash

### version control
PROGRAM_NAME="DOSBOX-AUTO"
VERSION="0.1.0"
AUTHOR="Huang YunXuan"
YEAR="2020"

### global vars ###
_dosbox_args=()
_dosbox_excutable=`which dosbox`
_dosbox_workdir=${DOSBOX_AUTO_WORKDIR:="."}
_dosbox_extra_path=${DOSBOX_AUTO_EXTRA_PATH:="./bin"}

### functions ###

# assemble log message (with a timestamp)
# Set $PROGRAM to a string to have it added to the output.
function msg() {
    if [[ -z "${PROGRAM}" ]]; then
        echo "$(date +"%b %d %H:%M:%S") $(hostname -s) [$$] $@"
    else
        echo "$(date +"%b %d %H:%M:%S") $(hostname -s) ${PROGRAM}[$$]: $@"
    fi
}

# log something
function log() {
    msg "$@"
}

# error msg
function error() {
    msg "ERROR: $@"
}

# help message
function print_help() {
cat << EOF
$PROGRAM_NAME $VERSION Copyright (c) $YEAR $AUTHOR

This is a simple script to help you run DOSBox with custom 
command executed, providing convenience for your auto int-
ergration and test.

If arguments provided correctly, this script will automat-
ically set the #PATH# variable and switch to your workdir 
in DOSBox.

Usage:
    -d|--dosbox     [somewhere, default to `which dosbox`]
                    Your DOSbox executable path.

    -x|--extra-path [somewhere, default to "./bin"]
                    Your extra executable path.

    -w|--workdir    [somewhere, default to "."]
                    Your working directory (ie. source code folder).
                    This will be mounted to C:
                    
    -c|--command    [commmand]
                    Extra DOS command (enclosed with double quotes).
                    This can be specified multiple times and will be
                    executed in the given order.
EOF
}

# run dosbox with settings from global variables
function start_dosbox() {
    ${_dosbox_excutable} "${_dosbox_extra_path[@]}" "${_dosbox_workdir[@]}" "${_dosbox_args[@]}"
}

# parse all arguments in a case switch
function parse_args() {
    while [[ $# > 0 ]]; do
        current_arg="$1"

        # 注意&&与||在多个连续混用的时候是如何结合的
        case $current_arg in
            -d|--dosbox)
            shift
            [[ $# -eq 0 ]] && log "Missing argument for $current_arg" && exit 1
            _dosbox_excutable="$1"
            ;;
            -x|--extra-path)
            shift
            [[ $# -eq 0 ]] && log "Missing argument for $current_arg" && exit 1
            _dosbox_extra_path="$1"
            ;;
            -w|--workdir)
            shift
            [[ $# -eq 0 ]] && log "Missing argument for $current_arg" && exit 1
            _dosbox_workdir="$1"
            ;;
            -c|--command)
            shift
            [[ $# -eq 0 ]] && log "Missing argument for $current_arg" && exit 1
            _dosbox_args+=("-c")
            _dosbox_args+=("$1")
            ;;
            help|--help|h|-h)
            print_help
            exit 0
            ;;
            *)
            error "Unrecognized argument $1"
            log "Run with \"help\" to get usage."
            exit 1
            ;;
        esac
        # shift argument list
        shift
    done
    
    # Process --extra-path and --workdir
    if [[ ! -z "${_dosbox_extra_path}" ]]; then
        [[ ! -d "${_dosbox_extra_path}" ]] && log "The given extra path is not found!" && exit 1
        _dosbox_extra_path=(
            "-c"
            "mount c ${_dosbox_extra_path}"
            "-c"
            "set path=Z:\\;C:\\"
        )
    else
        _dosbox_extra_path=()
    fi
    
    if [[ ! -z "${_dosbox_workdir}" ]]; then
        [[ ! -d "${_dosbox_workdir}" ]] && log "The given workdir is not found!" && exit 1
        _dosbox_workdir=(
            "-c"
            "mount d ${_dosbox_workdir}"
            "-c"
            "D:"
        )
    else
        _dosbox_workdir=()
    fi
}

### Begin ###
parse_args $@
log "Parse Complete"
log "Excutable: ${_dosbox_excutable}"
log "Extra path: ${_dosbox_extra_path[@]}"
log "Workdir: ${_dosbox_workdir[@]}"
log "Arguments: ${_dosbox_args[@]}"
log "Starting DOSBox"
start_dosbox
