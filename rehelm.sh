#!/bin/sh
# Reset helm chart for cluster
# Start call to helm upgrade with any passed arguments
# Depends on:
#   vars.sh (via set_config.sh)
source set_config.sh

# Timeout from:
# https://zero-to-jupyterhub.readthedocs.io/en/latest/administrator/optimization.html#pulling-images-before-users-arrive
# Allows pre-pulling of new Docker images on install / upgrade.
helm upgrade $* \
    --cleanup-on-fail \
    $RELEASE \
    jupyterhub/jupyterhub  \
    --atomic \
    --timeout 15m0s \
    --namespace=$NAMESPACE \
    --create-namespace \
    --version=$JHUB_VERSION \
    --values config.yaml
