# Teardown everything
. vars.sh
helm delete $RELEASE --purge
kubectl delete namespace $NAMESPACE
gcloud container clusters delete $JHUB_CLUSTER --region $REGION
