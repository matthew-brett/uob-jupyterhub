# From https://github.com/dirkcgrunwald/zero-to-jupyterhub-k3s/blob/master/basic-with-nfs-volumes/README.md
# Also
# https://www.linuxtechi.com/configure-nfs-persistent-volume-kubernetes/
source set_config.sh

kubectl create namespace $NAMESPACE

kubectl create -f nfs-configs/nfs_deployment.yaml
kubectl create -f nfs-configs/nfs_service.yaml
./tools/kube_tpl_create.sh nfs-configs/nfs_pv_pvc_tpl.yaml
./tools/kube_tpl_create.sh nfs-configs/nfs_pv_pvc_data_tpl.yaml

echo Next run
echo source configure_jhub.sh
