#!/bin/bash
# Master script to initialize Kubernetes according to specs in:
#
# https://zero-to-jupyterhub.readthedocs.io/en/latest/create-k8s-cluster.html
#
# Depends on:
#   vars.sh (via config.sh)
source set_config.sh

# Give your account permissions to perform all administrative actions needed.
kubectl create clusterrolebinding cluster-admin-binding \
  --clusterrole=cluster-admin \
  --user=$EMAIL

echo Next run
echo source setup_helm.sh
