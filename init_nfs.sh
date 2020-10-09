#!/bin/sh
# Deploy NFS server, set up PersistentVolume and
# PersistentVolumeClaim for home directories, and a data
# directory.
source set_config.sh

# Put into main namespace
kubectl create namespace $NAMESPACE

# Set up NFS server
# Complete YaML files with env vars.
export CLUSTER_DISK
envsubst < nfs-configs/nfs_deployment_tpl.yaml | kubectl create -f -

kubectl create -f nfs-configs/nfs_service.yaml

# Set up PV, PVC for home dirs and data directory.
export NAMESPACE
export NFS_PV_NAME="nfs"
export NFS_DISK_PATH=$HOME_PATH
export NFS_ACCESS_MODE=ReadWriteMany
envsubst < nfs-configs/nfs_pv_pvc_tpl.yaml | kubectl create -f -
export NFS_PV_NAME="nfs-data"
export NFS_DISK_PATH=$DATA_PATH
export NFS_ACCESS_MODE=ReadOnlyMany
envsubst < nfs-configs/nfs_pv_pvc_tpl.yaml | kubectl create -f -

echo Next run
echo source configure_jhub.sh
