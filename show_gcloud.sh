#!/bin/sh
# Show gcloud resources
echo "Clusters:"
gcloud container clusters list
echo "Instances:"
gcloud compute instances list
echo "Disks:"
gcloud compute disks list
