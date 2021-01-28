#!/bin/sh
# Teardown gcloud

# Depends on:
#   vars.sh

. set_config.sh

# https://cloud.google.com/sdk/gcloud/reference/container/clusters/delete
gcloud container clusters delete $JHUB_CLUSTER ${CLUSTER_SPEC} --quiet
