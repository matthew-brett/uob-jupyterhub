# Storage for the cluster

## Create, format storage

<https://cloud.google.com/compute/docs/disks/add-persistent-disk#gcloud>


```bash
# Set default zone / region
. vars.sh

DISK_NAME=uobhub-home-disk

# https://cloud.google.com/compute/docs/gcloud-compute#set_default_zone_and_region_in_your_local_client
gcloud config set compute/zone $ZONE
gcloud config set compute/region $REGION
```

```
# Create the disk
# Size minimum is 10GB
gcloud compute disks create \
    --size=10GB \
    --zone $ZONE \
    --type pd-standard \
    ${DISK_NAME}

gcloud compute disks list
```

```
# Create an instance
. vars.sh
gcloud compute instances create \
    test-machine \
    --image debian-10-buster-v20200910 \
    --image-project debian-cloud \
    --machine-type=g1-small \
    --zone $ZONE

gcloud compute instances describe test-machine
```

```
# Attach the disk
gcloud compute instances attach-disk \
    test-machine \
    --disk ${DISK_NAME}
```

Now follow instructions at <https://cloud.google.com/compute/docs/disks/add-persistent-disk#gcloud>.

```
# SSH into instance
MACHINE=test-machine
gcloud beta compute ssh --zone $ZONE $MACHINE --project $PROJECT_ID
```

```
# Then
sudo lsblk  # Check disk device id
```

```
# Set device ID, mount point, permissions
DEVICE=sdb
MNT_POINT=/mnt/disks/data
PERMISSIONS="a+rw"
```

```
# Format
sudo mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard \
   /dev/$DEVICE
```

```
# Permissions
sudo mkdir -p $MNT_POINT
sudo mount -o discard,defaults /dev/$DEVICE $MNT_POINT
sudo chmod ${PERMISSIONS} $MNT_POINT
```

Teardown instance:

```
gcloud compute instances delete test-machine
```

## Resize disk

```
# https://cloud.google.com/compute/docs/disks/add-persistent-disk#resize_pd
DISK_NAME=uobhub-home-disk
DISK_SIZE=12
gcloud compute disks resize $DISK_NAME \
   --size $DISK_SIZE --zone=$ZONE
```

## Use pre-existing volumes

<https://cloud.google.com/kubernetes-engine/docs/how-to/persistent-volumes/preexisting-pd>

<https://kubernetes.io/docs/tasks/configure-pod-container/configure-persistent-volume-storage/>

## Test storage

```
# Test cluster
. vars.sh
gcloud container clusters create \
    --machine-type=g1-small \
    --num-nodes 1 \
    --cluster-version latest \
    --node-locations $ZONE \
    test-cluster
```

Some useful commands.  Don't run these all at once.

```
# Useful commands
# Create pod
kubectl create -f configs/test_pod.yaml
# Show pod status
kubectl get pods
# Get more detail on pod status
kubectl get pod test-pd --output=yaml
# Show pod logs
kubectl logs pods/test-pd
# Execute command in pod
kubectl exec test-pd --stdin --tty -- /bin/sh
# Delete pod
kubectl delete pods test-pd
```

See also <https://kubernetes.io/docs/tasks/debug-application-cluster/determine-reason-pod-failure/>

## Single disk procedure

```
# Setup
kubectl create -f configs/data_volume.yaml
kubectl create -f configs/test_pd_deployment.yaml
kubectl get pod
```

```
# Test example.
kubectl exec test-deployment-5d8cb48cdd-m7b6x --stdin --tty -- /bin/sh
```

```
# Cleanup
kubectl delete deployment test-deployment
kubectl delete pvc pv-claim-demo
kubectl delete pv pv-demo
```

## NFS procedure

```
# Setup
kubectl create -f configs/data_volume.yaml
kubectl create -f nfs-configs/nfs_deployment.yaml
kubectl create -f nfs-configs/nfs_service.yaml
kubectl create -f nfs-configs/nfs_pv_pvc.yaml
kubectl create -f nfs-configs/test_nfs_deployment.yaml
kubectl get pod
```

```
# Test example.
kubectl exec --stdin --tty test-deployment-5d8cb48cdd-m7b6x -- /bin/sh
```

```
# Cleanup
kubectl delete deployment test-deployment
kubectl delete service nfs-server
kubectl delete deployment nfs-server
kubectl delete pvc pv-claim-demo
kubectl delete pv pv-demo
kubectl delete pvc nfs
kubectl delete pv nfs
```

## Finally

```
gcloud compute instances list
```

```
cluster_uri=$(gcloud container clusters list --uri)
gcloud container clusters delete $cluster_uri --quiet
```
