#!/bin/bash

set -Eeuo pipefail

STEP=$1
BUILD_DIR="$PWD/build/$STEP"
SRC_DIR="$PWD/steps/$STEP"
export PIPENV_VENV_IN_PROJECT=true

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR" || exit

cp -r "$SRC_DIR/src" "$BUILD_DIR/src"
cp -r "$SRC_DIR/Pipfile" "$BUILD_DIR/Pipfile"
cp -r "$SRC_DIR/Pipfile.lock" "$BUILD_DIR/Pipfile.lock"

pipenv install

echo "Creating deployment package ..."
cp -r "$BUILD_DIR"/.venv/lib/*/site-packages/* "$BUILD_DIR"

pipenv --rm

echo "Done!"
