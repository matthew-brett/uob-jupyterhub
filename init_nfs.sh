# From https://github.com/dirkcgrunwald/zero-to-jupyterhub-k3s/blob/master/basic-with-nfs-volumes/README.md
# Also
# https://www.linuxtechi.com/configure-nfs-persistent-volume-kubernetes/
source set_config.sh

kubectl create -f configs/data_volume.yaml
kubectl create -f nfs-configs/nfs_deployment.yaml
kubectl create -f nfs-configs/nfs_service.yaml
./tools/kube_tpl_create.sh nfs-configs/nfs_pv_pvc_tpl.yaml
