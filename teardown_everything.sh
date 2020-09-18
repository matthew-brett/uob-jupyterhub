#!/bin/sh
# Teardown everything
# Depends on:
#   vars.sh
#   config.yaml
. set_config.sh

helm delete $RELEASE

kubectl delete service nfs-server
kubectl delete deployment nfs-server
kubectl delete pvc nfs
kubectl delete pv nfs
kubectl delete pvc nfs-data
kubectl delete pv nfs-data

kubectl delete namespace $NAMESPACE
gcloud container clusters delete $JHUB_CLUSTER --region $REGION --quiet

# Check teardown
./show_gcloud.sh
