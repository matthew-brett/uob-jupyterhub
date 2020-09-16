# Source this file.
PROJECT_ID=uob-jupyterhub
JHUB_CLUSTER=jhub-cluster
RELEASE=jhub
NAMESPACE=jhub
# VM type for running the always-on part of the infrastructure.
DEFAULT_MACHINE=n1-custom-1-6656
DEFAULT_DISK_SIZE=30Gi
# VM type for housing the users.
USER_MACHINE=e2-standard-2
USER_DISK_SIZE=30Gi
# Maximum number nodes in the cluster.
MAX_NODES=23
# Helm chart for JupyterHub / Kubernetes. See:
# https://discourse.jupyter.org/t/trouble-getting-https-letsencrypt-working-with-0-9-0-beta-4/3583/5?u=matthew.brett
# and
# https://jupyterhub.github.io/helm-chart/
JHUB_VERSION="0.9.0-n233.hcd1eff7a"
# Region on which the cluster will run; see notes
REGION=europe-west2
# Zone within region; see notes
ZONE=europe-west2-b
EMAIL=matthew.brett@gmail.com
UOBHUB_IP=34.105.129.229
# Dataset to which billing information will be written
# See the Google Cloud Billing Export pane for detail; enable daily cost
# detail, and set up / name dataset there.
RESOURCE_DATASET=uob_jupyterhub_billing
