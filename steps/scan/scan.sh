#!/bin/sh

set -eu

S3_BUCKET="${S3_BUCKET%/*}"
DATE="$(date +%Y/%m/%d)"

# shellcheck disable=SC2046
# shellcheck disable=SC2183
export $(printf "AWS_ACCESS_KEY_ID=%s AWS_SECRET_ACCESS_KEY=%s AWS_SESSION_TOKEN=%s" \
    $(aws sts assume-role \
        --role-arn "arn:aws:iam::$ACCOUNT:role/OrganizationAccountAccessRole" \
        --role-session-name "infrastructure-scanner" \
        --query "Credentials.[AccessKeyId,SecretAccessKey,SessionToken]" \
        --output text)\
)

# Execute Cloudsploit
./index.js --json=results.json

# Hop out of the scan account back into the regular account
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN

aws s3 cp results.json "s3://$S3_BUCKET/$DATE/$ACCOUNT.json"
