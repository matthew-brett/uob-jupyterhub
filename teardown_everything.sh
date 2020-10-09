#!/bin/sh
# Teardown everything
# Depends on:
#   vars.sh
#   config.yaml
. set_config.sh

helm delete $RELEASE

kubectl delete namespace $NAMESPACE

gcloud container clusters delete $JHUB_CLUSTER --zone $ZONE --quiet

# Check teardown
./show_gcloud.sh
