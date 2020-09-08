#!/bin/sh
# Reset helm chart for cluster
# Start call to helm upgrade with any passed arguments
if [ -z "$JHUB_VERSION" ]; then
    . vars.sh
fi
helm upgrade $* \
    --cleanup-on-fail \
    $RELEASE jupyterhub/jupyterhub  \
    --namespace=$NAMESPACE \
    --version=$JHUB_VERSION \
    --values config.yaml
