# Master script to build cluster according to specs in:
#
# Run after
#   source init_gjhub.sh
#
# Depends on:
# vars.sh
# config.yaml
source vars.sh

# Apply Helm chart.
helm upgrade --install $RELEASE jupyterhub/jupyterhub \
  --namespace $NAMESPACE  \
  --version=$JHUB_VERSION \
  --values config.yaml

# Optional, autocompletion:
kubectl config set-context $(kubectl config current-context) --namespace $NAMESPACE

# Pause here.
kubectl get pod --namespace $NAMESPACE
kubectl get service --namespace $NAMESPACE

# Consider the following to reset https, if not enabled.
# kubectl get secrets
# kubectl delete secret proxy-public-tls-acme
# kubectl get secrets
# kubectl delete pods $(kubectl get pods -o custom-columns=POD:metadata.name | grep autohttps-)
