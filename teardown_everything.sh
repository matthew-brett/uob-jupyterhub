#!/bin/sh
# Teardown everything
# Depends on:
#   vars.sh
#   config.yaml
. set_config.sh

echo "Deleting $RELEASE on $JHUB_CLUSTER".
read -n1 -r -p "Press y to continue, any other key to cancel." key

if [ "$key" = 'y' ]; then
    helm delete $RELEASE

    kubectl delete namespace $NAMESPACE

    gcloud container clusters delete $JHUB_CLUSTER --zone $ZONE --quiet

    # Check teardown
    ./show_gcloud.sh
else
    echo "Cancelled"
fi
