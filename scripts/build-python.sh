#!/bin/bash

set -Eeuo pipefail

INCLUDE_VENV=false

print_usage () {
    cat <<EOF
Usage: $0 [TARGET] [options] Build the python target project

Options:
  -v, --include-venv    Indicates whether the venv should be included
  -h, --help            Print usage
EOF
}

if [ $# -lt 1 ] || [[ "$1" =~ ^-{1,2}(h$|help)$ ]]; then
    print_usage; exit 1
else
    FOLDER="$1"; shift;
    while [[ $# -gt 0 ]]; do
        opt="$1"; shift;
        case $opt in
            "-v"|"--include-venv" ) INCLUDE_VENV=true;;
            *                     ) echo "ERROR: Invalid option: \"$opt\"" >&2; print_usage; exit 1;;
        esac
    done
fi

BUILD_DIR="$PWD/build/$FOLDER"
SRC_DIR="$PWD/$FOLDER"

export PIPENV_VENV_IN_PROJECT=true

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR" || exit

cp -r "$SRC_DIR/src" "$BUILD_DIR/src"
cp -r "$SRC_DIR/Pipfile" "$BUILD_DIR/Pipfile"
cp -r "$SRC_DIR/Pipfile.lock" "$BUILD_DIR/Pipfile.lock"

if [ "$INCLUDE_VENV" == true ]; then
    echo "Creating deployment package ..."
    pipenv install
    cp -r "$BUILD_DIR"/.venv/lib/*/site-packages/* "$BUILD_DIR"
    pipenv --rm
fi

echo "Done!"
