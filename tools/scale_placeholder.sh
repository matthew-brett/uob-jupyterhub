#!/bin/bash
n_replicas=$1
if [ -z "$n_replicas" ]; then
    echo "Specify number of replicas"
    exit 1
fi
MY_DIR=$(dirname "${BASH_SOURCE[0]}")
source ${MY_DIR}/../set_config.sh
# https://gitter.im/jupyterhub/jupyterhub?at=5f885a30bbffc02b581aafe8
# https://kubernetes.io/docs/tasks/run-application/scale-stateful-set/
kubectl scale sts/user-placeholder --replicas ${n_replicas}
