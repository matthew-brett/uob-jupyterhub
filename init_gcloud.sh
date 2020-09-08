# Initialize cluster on GCloud according to specs in:
#
# https://zero-to-jupyterhub.readthedocs.io/en/latest/google/step-zero-gcp.html
#
# Depends on:
#   vars.sh (via set_config.sh)
source set_config.sh

# Create the main cluster.
gcloud container clusters create \
  --machine-type $DEFAULT_MACHINE \
  --num-nodes 2 \
  --cluster-version latest \
  --node-locations $ZONE \
  --region $REGION \
  $JHUB_CLUSTER

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

echo Next run
echo source init_kubernetes.sh
