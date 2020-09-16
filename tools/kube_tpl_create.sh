#!/bin/bash
yaml_file=$1
if [ -z "$yaml_file" ]; then
    echo "Pass YaML filename as argument"
    exit 1
fi
MY_DIR=$(dirname "${BASH_SOURCE[0]}")
set -a
. ${MY_DIR}/../vars.sh
set +a
envsubst < $yaml_file | kubectl create -f -
