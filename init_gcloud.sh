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
# Surge values are default; recording here for completeness.
# https://cloud.google.com/kubernetes-engine/docs/concepts/cluster-upgrades
# Some settings from
# https://docs.datahub.berkeley.edu/en/latest/admins/cluster-config.html
gcloud container clusters create \
  --machine-type $DEFAULT_MACHINE \
  --num-nodes ${DEFAULT_NODES} \
  --min-nodes ${DEFAULT_NODES} \
  --max-nodes ${MAX_DEFAULT_NODES:-$DEFAULT_NODES} \
  --enable-autoscaling \
  --image-type=ubuntu_containerd \
  --cluster-version latest \
  --region $REGION \
  --node-locations $ZONE \
  --project ${PROJECT_ID} \
  --disk-size ${DEFAULT_DISK_SIZE:-30Gi} \
  --disk-type ${DEFAULT_DISK_TYPE:-pd-standard} \
  --max-surge-upgrade 1 \
  --max-unavailable-upgrade 0 \
  --enable-ip-alias \
  $JHUB_CLUSTER

# Consider other security options mentioned in page above:
#    --enable-network-policy \
#    --create-subnetwork="" \

# Optional - create a special user cluster.
if [ ${USER_POOL:-1} -ne 0 ]; then
    gcloud container node-pools create user-pool \
    --machine-type $USER_MACHINE \
    --num-nodes ${USER_MIN_NODES:-0} \
    --enable-autoscaling \
    --image-type=ubuntu_containerd \
    --min-nodes ${USER_MIN_NODES:-0} \
    --max-nodes ${USER_MAX_NODES:-23} \
    --node-labels hub.jupyter.org/node-purpose=user \
    --node-taints hub.jupyter.org_dedicated=user:NoSchedule \
    --region $REGION \
    --node-locations $ZONE \
    --project ${PROJECT_ID} \
    --disk-size ${USER_DISK_SIZE:-30Gi} \
    --disk-type ${USER_DISK_TYPE:-pd-standard} \
    --cluster $JHUB_CLUSTER
fi

# Give your account permissions to perform all administrative actions needed.
kubectl create clusterrolebinding cluster-admin-binding \
  --clusterrole=cluster-admin \
  --user=$EMAIL

# Set Kubernetes credentials to this cluster
gcloud container clusters get-credentials $JHUB_CLUSTER --region $REGION

echo Next run
echo source setup_helm.sh
