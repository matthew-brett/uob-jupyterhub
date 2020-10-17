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
SIZE=64GB
STORAGE_TYPE="pd-ssd"
gcloud compute disks create \
    --size=$SIZE \
    --zone $ZONE \
    --type ${STORAGE_TYPE} \
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

## Optimizing

Thanks to Yaroslav Naumenko from [Ancoris](https://www.ancoris.com) for
pointing me at the information below, and helping me working through the
implications.

See <https://cloud.google.com/compute/docs/disks> and
<https://cloud.google.com/compute/docs/disks/performance>.

Persistent disks (SD) are much slower than persistent SSD (SSD) for
IOPS.  There's an intermediate option called "balanced" persistent disks (BD).

For a containing VM with 1 CPU and a 100GB disk, maximum IOPS appears to be limited by disk size. Here are the maximum read IOPS for the disk types. Because the maximum is constrained by disk size, IOPS is a simple linear function of disk size.

* 100GB SD : 0.75 / GB = 75 (!)
* 100GB BD : 6 / GB = 600
* 100GB SSD : 30 / GB = 3000

Yes, that's a factor of 40 speed-up for SSD compared to SD, at least,
potentially.

It looks like the number of CPUs on the VM starts to become a factor when the
disks become large enough to allow fairly high IOPS.

For N1 machines, SDs run a little faster with >7 CPUs, once your disk gets to
3000 IOPS GB constraint - but that's a 4TB disk, and you'll get a maximum 66%
speedup for your 8 CPUs when you reach 6.66TB.

For N1 machines and SSDs, you only get an IOPS speedup when you reach 16 CPUs, and a disk constraint of 15,000 IOPS - 500GB.

## Moving over to another disk

[Snapshots won't work when new disk is smaller than
original](https://cloud.google.com/compute/docs/disks/restore-and-delete-snapshots).
Will have to shutdown cluster, create new disk, format, mount, then mount the
original disk, and rsync copy.

## Finally

```
gcloud compute instances list
```

```
cluster_uri=$(gcloud container clusters list --uri)
gcloud container clusters delete $cluster_uri --quiet
```

## Moving stuff from disk to disk

Do as above with the new disk.  Then:

```
OLD_DISK=jhub-home-data
# Attach the disk
gcloud compute instances attach-disk \
    $MACHINE \
    --disk $OLD_DISK
```

Mount the old disk:

```
OLD_DEVICE=<what you found with sudo lsblk>
OLD_MNT_POINT=/mnt/disks/old-data
sudo mkdir -p $OLD_MNT_POINT
sudo mount -o discard,defaults /dev/$OLD_DEVICE $OLD_MNT_POINT
```

You can then `sudo apt install rsync` and something like:

```
cd /mnt/disks
sudo rsync -aAXv old-data/ data/
```
