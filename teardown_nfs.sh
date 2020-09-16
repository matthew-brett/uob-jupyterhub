#!/bin/sh
# Teardown nfs

. set_config.sh

kubectl delete service nfs-server
kubectl delete deployment nfs-server
kubectl delete pvc pv-claim-demo
kubectl delete pv pv-demo
kubectl delete pvc nfs
kubectl delete pv nfs
kubectl delete pvc nfs-data
kubectl delete pv nfs-data
