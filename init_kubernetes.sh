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

# Next two lines orphaned by upgrade to Helm3
# See commit 046b07c in zero-to-jupyterhub-k8s
# Remove these before next cluster startup.
# Set up a ServiceAccount for use by tiller.
kubectl --namespace kube-system create serviceaccount tiller

# Give the ServiceAccount full permissions to manage the cluster.
kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller

# Initialize storage classes for SSD and standard storage
# https://zero-to-jupyterhub.readthedocs.io/en/latest/customizing/user-storage.html
# Needed for config.yaml setting of storage
kubectl apply -f configs/pd_ssd.yaml
kubectl apply -f configs/pd_std.yaml

echo Next run
echo source setup_helm.sh
