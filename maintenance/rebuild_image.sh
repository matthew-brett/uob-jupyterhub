# Rebuilding docker image

```bash
# Set default zone / region
. vars.sh

# https://cloud.google.com/compute/docs/gcloud-compute#set_default_zone_and_region_in_your_local_client
gcloud config set compute/zone $ZONE
gcloud config set compute/region $REGION
```

```
# Create a somewhat beefy instance
. vars.sh
gcloud compute instances create \
    test-machine \
    --image container-vm-v20140710 \
    --image-project google-containers \
    --image debian-10-buster-v20200910 \
    --image-project debian-cloud \
    --machine-type=n1-standard-4 \
    --zone $ZONE

gcloud compute instances describe test-machine
```

Now follow instructions at <https://cloud.google.com/compute/docs/disks/add-persistent-disk#gcloud>.

```
# SSH into instance
MACHINE=test-machine
gcloud beta compute ssh --zone $ZONE $MACHINE --project $PROJECT_ID
```

```
# Then
sudo bash
apt install docker git
git clone https://github.com/matthew-brett/uob-docker.git
cd uob-docker
docker build .
```

Teardown instance:

```
gcloud compute instances delete test-machine --quiet
```
