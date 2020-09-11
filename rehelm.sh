#!/bin/sh
# Reset helm chart for cluster
# Start call to helm upgrade with any passed arguments
if [ -z "$JHUB_VERSION" ]; then
    . vars.sh
fi
# Timeout from:
# https://zero-to-jupyterhub.readthedocs.io/en/latest/administrator/optimization.html#pulling-images-before-users-arrive
# Allows pre-pulling of new Docker images on install / upgrade.
helm upgrade $* \
    --cleanup-on-fail \
    $RELEASE \
    jupyterhub/jupyterhub  \
    --timeout 10m0s \
    --namespace=$NAMESPACE \
    --create-namespace \
    --version=$JHUB_VERSION \
    --values config.yaml
