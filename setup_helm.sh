#!/bin/bash
# Restore state for configuration.
# Source config
source set_config.sh

# Kubernetes config
source set_kconfig.sh

# optional autocompletion
kubectl config set-context $(kubectl config current-context) --namespace ${NAMESPACE}

# Check correct version of helm is installed
HELM_VER=$(helm version --short)
if [ "${HELM_VER:0:3}" != "v3." ]; then
    echo run install_helm.sh for helm 3
    return 1
fi

# Reinit jupyterhub helm chart repo
helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
helm repo update

# Show what's running
kubectl get pod --namespace $NAMESPACE

echo Next run
echo source init_nfs.sh
