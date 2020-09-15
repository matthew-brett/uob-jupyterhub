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
gcloud beta compute ssh --zone $ZONE test-machine --project $PROJECT_ID
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

## Use pre-existing volumes

<https://cloud.google.com/kubernetes-engine/docs/how-to/persistent-volumes/preexisting-pd>

<https://kubernetes.io/docs/tasks/configure-pod-container/configure-persistent-volume-storage/>

## Test storage

```
# Test cluster
gcloud container clusters create \
    --machine-type=g1-small \
    --num-nodes 1 \
    --cluster-version latest \
    --node-locations $ZONE \
    test-cluster
```

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

Procedure:

```
# Setup
kubectl create -f configs/data_volume.yaml
kubectl create -f test_deployment.yaml
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
