# From https://github.com/dirkcgrunwald/zero-to-jupyterhub-k3s/blob/master/basic-with-nfs-volumes/README.md
# Also
# https://www.linuxtechi.com/configure-nfs-persistent-volume-kubernetes/
source set_config.sh

helm repo add stable https://kubernetes-charts.storage.googleapis.com
helm repo update
helm install \
    $NFS_RELEASE \
    stable/nfs-server-provisioner \
    --namespace $NFS_NAMESPACE \
    --create-namespace \
    --values=$NFS_CONFIG

# kubectl apply -f make-shared-nfs-volume.yaml

# Remove with:
# kubectl delete pvc jupyterhub-shared-volume
