# Storage for the cluster

## Create, format storage

<https://cloud.google.com/compute/docs/disks/add-persistent-disk#gcloud>


```bash
# Set default zone / region
. vars.sh

DISK_NAME=${CLUSTER_DISK}

# https://cloud.google.com/compute/docs/gcloud-compute#set_default_zone_and_region_in_your_local_client
gcloud config set compute/zone $ZONE
gcloud config set compute/region $REGION
gcloud config set project $PROJECT_ID
```

```
# Create the disk
# Size minimum is 10GB
SIZE=200GB
gcloud compute disks create \
    --size=$SIZE \
    --zone $ZONE \
    --type pd-standard \
    ${DISK_NAME}

gcloud compute disks list
```

```
# Create an instance
. vars.sh
MACHINE=test-machine
gcloud compute instances create \
    $MACHINE \
    --image debian-10-buster-v20200910 \
    --image-project debian-cloud \
    --machine-type=g1-small \
    --zone $ZONE

gcloud compute instances describe $MACHINE
```

```
# Attach the disk
gcloud compute instances attach-disk \
    $MACHINE \
    --disk ${DISK_NAME}
```

Now follow instructions at <https://cloud.google.com/compute/docs/disks/add-persistent-disk#gcloud>.

```
# SSH into instance
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
PERMISSIONS="a+r"
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

```
# Make the expected disk structure
cd $MNT_POINT
sudo mkdir data 2020-homes
sudo chmod a+rw 2020-homes
```

Teardown instance:

```
gcloud compute instances delete $MACHINE
```

## Resize disk

<https://cloud.google.com/compute/docs/disks/add-persistent-disk#resize_pd>

```
. vars.sh
DISK_NAME=${CLUSTER_DISK}
DISK_SIZE=200
gcloud compute disks resize $DISK_NAME \
   --size $DISK_SIZE --zone=$ZONE
```

## Snapshots

<https://cloud.google.com/compute/docs/disks/create-snapshots>

```
# Show snapshots
gcloud compute snapshots list
```

```
DISK_NAME=${CLUSTER_DISK}
gcloud compute disks snapshot $DISK_NAME \
. vars.sh
DISK_NAME=${CLUSTER_DISK}
gcloud compute disks snapshot $DISK_NAME --zone $ZONE
```

Consider
[schedule](https://cloud.google.com/compute/docs/disks/scheduled-snapshots)
such as:

```
SCHEDULE_NAME=daily-uob
gcloud compute resource-policies create snapshot-schedule \
    $SCHEDULE_NAME \
    --description "Daily backups of UoBhub disk" \
    --max-retention-days 14 \
    --start-time 04:00 \
    --daily-schedule
```

Follow with:

```
# Attach schedule to disk
gcloud compute disks add-resource-policies ${DISK_NAME} \
    --resource-policies ${SCHEDULE_NAME} \
    --zone $ZONE
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

Assumes GCE disk exists named `uobhub-data-disk`:

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

Assumes GCE disks exist named `uobhub-data-disk` and `uobhub-home-disk`:

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
