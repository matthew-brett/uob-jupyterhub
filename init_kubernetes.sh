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

# Initialize storage classes for SSD and standard storage
# https://zero-to-jupyterhub.readthedocs.io/en/latest/customizing/user-storage.html
# Needed for config.yaml setting of storage
kubectl apply -f configs/pd_ssd.yaml
kubectl apply -f configs/pd_std.yaml

echo Next run
echo source setup_helm.sh
