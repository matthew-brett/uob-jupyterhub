# Source this file.
PROJECT_ID=uob-jupyterhub
JHUB_CLUSTER=jhub-cluster
RELEASE=jhub
NAMESPACE=jhub
# VM type for running the always-on part of the infrastructure.
DEFAULT_MACHINE=n1-standard-2
# VM disk size per node.
DEFAULT_DISK_SIZE=30Gi
# VM type for housing the users.
USER_MACHINE=e2-standard-2
# VM disk size per node.
USER_DISK_SIZE=30Gi
# Maximum number nodes in the cluster.
MAX_NODES=23
# Helm chart for JupyterHub / Kubernetes. See:
# https://discourse.jupyter.org/t/trouble-getting-https-letsencrypt-working-with-0-9-0-beta-4/3583/5?u=matthew.brett
# and
# https://jupyterhub.github.io/helm-chart/
# From datahub commit be8edd1
JHUB_VERSION="0.9.0-n335.hcc6c02d3"
# Region on which the cluster will run; see notes
REGION=europe-west2
# Zone within region; see notes
ZONE=europe-west2-b
EMAIL=matthew.brett@gmail.com
# Dataset to which billing information will be written
# See the Google Cloud Billing Export pane for detail; enable daily cost
# detail, and set up / name dataset there.
RESOURCE_DATASET=uob_jupyterhub_billing
# Disk for data and homes
CLUSTER_DISK=jhub-home-data
HOME_PATH=/2020-homes/
DATA_PATH=/data/
