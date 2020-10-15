#!/bin/bash
# Re-initialized gcloud authorization
#
# https://zero-to-jupyterhub.readthedocs.io/en/latest/google/step-zero-gcp.html
#
# Depends on:
#   vars.sh (via set_config.sh)
source set_config.sh

# May need
# gcloud auth login

# Reset zonal cluster
gcloud container clusters get-credentials $JHUB_CLUSTER --zone $ZONE
