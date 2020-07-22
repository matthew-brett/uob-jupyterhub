# https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-usage-metering
# Set RESOURCE_DATASET in vars
. set_config.sh
gcloud container clusters update $JHUB_CLUSTER --region $REGION \
    --resource-usage-bigquery-dataset $RESOURCE_DATASET
gcloud container clusters describe $JHUB_CLUSTER \
  --format="value(resourceUsageExportConfig)"



