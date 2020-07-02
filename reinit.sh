# Source this file
# Source vars
. vars.sh
# Set project ID (just in case)
gcloud config set project $PROJECT_ID
# Reinstall helm v2
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash
# Reinit helm
helm init --service-account tiller --history-max 100 --wait
# Reinit jupyterhub helm chart repo
helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
helm repo update
# optional autocompletion
kubectl config set-context $(kubectl config current-context) --namespace ${NAMESPACE:-jhub}
# Reinit command
alias rehelm='helm upgrade $RELEASE jupyterhub/jupyterhub  --version=$JHUB_VERSION --values config.yaml'
# Show what's running
kubectl get pod --namespace $NAMESPACE
