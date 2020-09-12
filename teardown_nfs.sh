#!/bin/sh
# Teardown nfs

helm delete $NFS_RELEASE
kubectl delete namespace $NFS_NAMESPACE
kubectl delete storageclass jh-nfs-sc

# Check teardown
gcloud compute instances list

# Check disks
gcloud compute disks list
