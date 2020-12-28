# Source this file.
CONFIG_YAML=jh-secrets/config.yaml.uobhub
PROJECT_ID=uob-jupyterhub
JHUB_CLUSTER=jhub-cluster
RELEASE=jhub
NAMESPACE=jhub
# Disk for data and homes
CLUSTER_DISK=jhub-home-data-ssd
# VM type for running the always-on part of the infrastructure.
# May be able to get away with one machine.
# https://gitter.im/jupyterhub/jupyterhub?at=5f86fb48a1c81d0a7ee084af
DEFAULT_MACHINE=n1-standard-2
# Number of nodes running core
DEFAULT_NODES=1
# VM disk size per node, default pool.
DEFAULT_DISK_SIZE=30Gi
# VM disk type for default pool.
DEFAULT_DISK_TYPE=pd-ssd
# Whether to save a separate user pool.
# If 0, all USER_* vars ignored below.
USER_POOL=1
# VM type for housing the users.
USER_MACHINE=e2-highmem-2
# VM disk size per node.
USER_DISK_SIZE=30Gi
# Minimum number of nodes in the user cluster.
USER_MIN_NODES=0
# Maximum number of nodes in the user cluster.
USER_MAX_NODES=50
# VM disk type for user pool.
USER_DISK_TYPE=pd-standard
# Helm chart for JupyterHub / Kubernetes. See:
# https://discourse.jupyter.org/t/trouble-getting-https-letsencrypt-working-with-0-9-0-beta-4/3583/5?u=matthew.brett
# and
# https://jupyterhub.github.io/helm-chart/
JHUB_VERSION="0.10.3"
# Region on which the cluster will run; see notes
REGION=europe-west2
# Zone within region; see notes
ZONE=europe-west2-b
EMAIL=matthew.brett@gmail.com
# Dataset to which billing information will be written
# See the Google Cloud Billing Export pane for detail; enable daily cost
# detail, and set up / name dataset there.
RESOURCE_DATASET=uob_jupyterhub_billing
# Disk directories on CLUSTER_DISK (see above).
HOME_PATH=/2020-homes/
DATA_PATH=/data/
