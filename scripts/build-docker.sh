#!/bin/bash

set -Eeuo pipefail

STEP=$1
REPO="$(cd infra && terraform output -raw "$STEP"-repo)"

cd "steps/$STEP" || exit

aws ecr get-login-password | docker login "$REPO" -u "AWS" --password-stdin

docker build -t "$REPO":latest .
docker push "$REPO":latest
docker logout
