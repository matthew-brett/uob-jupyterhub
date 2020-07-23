#!/bin/sh
# Reset helm chart for cluster
if [ -z "$JHUB_VERSION" ]; then
    . vars.sh
fi
helm upgrade $* \
    $RELEASE jupyterhub/jupyterhub  \
    --namespace=$NAMESPACE \
    --version=$JHUB_VERSION \
    --values config.yaml
