# Master script to initialize cluster according to specs in:
#
# Depends on:
#   vars.sh
#   config.yaml
source set_config.sh

# Create the main cluster.
gcloud container clusters create \
  --machine-type $DEFAULT_MACHINE \
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
  --machine-type $USER_MACHINE \
  --num-nodes 0 \
  --enable-autoscaling \
  --min-nodes 0 \
  --max-nodes $MAX_NODES \
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

echo Next run
echo source build_gjhub.sh
