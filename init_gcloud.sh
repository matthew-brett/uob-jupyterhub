#!/bin/bash
# Initialize cluster on GCloud according to specs in:
#
# https://zero-to-jupyterhub.readthedocs.io/en/latest/google/step-zero-gcp.html
#
# Depends on:
#   vars.sh (via set_config.sh)
source set_config.sh

# Create the main cluster.
# Be careful to create a zonal cluster rather than a regional cluster; you get
# one zonal cluster for free.
# https://cloud.google.com/kubernetes-engine/pricing
gcloud container clusters create \
  --machine-type $DEFAULT_MACHINE \
  --num-nodes 2 \
  --cluster-version latest \
  --node-locations $ZONE \
  --zone $ZONE \
  --disk-size $DEFAULT_DISK_SIZE \
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
  --zone $ZONE \
  --disk-size $USER_DISK_SIZE \
  --cluster $JHUB_CLUSTER

# Set Kubernetes credentials to this cluster
gcloud container clusters get-credentials $JHUB_CLUSTER --zone $ZONE

echo Next run
echo source init_kubernetes.sh
