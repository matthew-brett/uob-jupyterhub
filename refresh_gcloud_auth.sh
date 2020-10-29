#!/bin/bash
# Re-initialized gcloud authorization
#
# https://zero-to-jupyterhub.readthedocs.io/en/latest/google/step-zero-gcp.html
#
# Depends on:
#   vars.sh (via set_config.sh)
source set_config.sh

echo May need "gcloud auth login"

# Reset zonal cluster
# https://stackoverflow.com/questions/36650642/did-you-specify-the-right-host-or-port-error-on-kubernetes
gcloud container clusters get-credentials $JHUB_CLUSTER \
    --zone $ZONE \
    --project ${PROJECT_ID}
