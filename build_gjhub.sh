# Master script to build cluster according to specs in:
#
# vars.sh
# config.yaml
source vars.sh

# Set project ID
gcloud config set project $PROJECT_ID

# Set default region and zone.
gcloud compute project-info add-metadata \
    --metadata google-compute-default-region=$REGION,google-compute-default-zone=$ZONE

# Create the main cluster.
gcloud container clusters create \
  --machine-type n1-standard-2 \
  --num-nodes 2 \
  --cluster-version latest \
  --node-locations $ZONE \
  --region $REGION \
  $JHUB_CLUSTER

# Give your account permissions to perform all administrative actions needed.
kubectl create clusterrolebinding cluster-admin-binding \
  --clusterrole=cluster-admin \
  --user=$EMAIL

# Optional - create a special user cluster.
gcloud beta container node-pools create user-pool \
  --machine-type n1-standard-2 \
  --num-nodes 0 \
  --enable-autoscaling \
  --min-nodes 0 \
  --max-nodes 3 \
  --node-labels hub.jupyter.org/node-purpose=user \
  --node-taints hub.jupyter.org_dedicated=user:NoSchedule \
  --node-locations $ZONE \
  --region $REGION \
  --cluster $JHUB_CLUSTER

# Set up a ServiceAccount for use by tiller.
kubectl --namespace kube-system create serviceaccount tiller

# Give the ServiceAccount full permissions to manage the cluster.
kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller

# Initialize helm and tiller.
helm init --service-account tiller --history-max 100 --wait

# Ensure that tiller is secure from access inside the cluster:
kubectl patch deployment tiller-deploy --namespace=kube-system --type=json --patch='[{"op": "add", "path": "/spec/template/spec/containers/0/command", "value": ["/tiller", "--listen=localhost:44134"]}]'

# Add JupyterHub Helm chart repository:
helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
helm repo update

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
