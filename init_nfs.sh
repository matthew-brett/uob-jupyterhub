#!/bin/sh
# Deploy NFS server, set up PersistentVolume and
# PersistentVolumeClaim for home directories, and a data
# directory.
source set_config.sh

# Put into main namespace
kubectl create namespace $NAMESPACE

# Set up NFS server
# Complete YaML files with variables from vars.sh,
# pass to kubectl create
./tools/kube_tpl_create.sh nfs-configs/nfs_deployment.yaml
kubectl create -f nfs-configs/nfs_service.yaml
# Set up PV, PVC for home dirs and data directory.
./tools/kube_tpl_create.sh nfs-configs/nfs_pv_pvc_tpl.yaml
./tools/kube_tpl_create.sh nfs-configs/nfs_pv_pvc_data_tpl.yaml

echo Next run
echo source configure_jhub.sh
