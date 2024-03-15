#!/bin/bash

set -Eeuo pipefail

print_usage () {
    cat <<EOF
Usage: $0 [TARGET] [options] Build the target container.

Options:
  -r, --repository [REPO] Indicates the desired container repository
  -h, --help              Print usage
EOF
}

if [ $# -lt 1 ] || [[ "$1" =~ ^-{1,2}(h$|help)$ ]]; then
    print_usage; exit 1
else
    STEP="$1"; shift;
    while [[ $# -gt 0 ]]; do
        opt="$1"
        shift;
        case "$opt" in
            "-r"|"--repository" ) REPO=$1; shift;;
            *                   ) echo "ERROR: Invalid option: \""$opt"\"" >&2; print_usage; exit 1;;
        esac
    done
fi

cd "$STEP" || exit 1

aws ecr get-login-password | docker login "$REPO" -u "AWS" --password-stdin

docker build -t "$REPO":latest .
docker push "$REPO":latest
docker logout
