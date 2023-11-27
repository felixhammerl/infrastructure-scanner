#!/bin/bash

set -Eeuo pipefail

FOLDER=$1
INCLUDE_VENV="${2:-"no"}"
BUILD_DIR="$PWD/build/$FOLDER"
SRC_DIR="$PWD/$FOLDER"
export PIPENV_VENV_IN_PROJECT=true

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR" || exit

cp -r "$SRC_DIR/src" "$BUILD_DIR/src"
cp -r "$SRC_DIR/Pipfile" "$BUILD_DIR/Pipfile"
cp -r "$SRC_DIR/Pipfile.lock" "$BUILD_DIR/Pipfile.lock"

if [ "$INCLUDE_VENV" == "--include-venv" ]; then
    echo "Creating deployment package ..."
    pipenv install
    cp -r "$BUILD_DIR"/.venv/lib/*/site-packages/* "$BUILD_DIR"
    pipenv --rm
fi

echo "Done!"
