# Set Kubernetes configuration

# Get variables
. vars.sh

# Reset cluster context, just in case
# Warning: Google Cloud specific; generalize in due course.
if [[ "${CLUSTER_SPEC}" =~ --region ]]; then
    # Regional cluster
    mid_fix=${REGION}
else
    # Zonal cluster
    mid_fix=${ZONE}
fi
kubectl config use-context gke_${PROJECT_ID}_${mid_fix}_${JHUB_CLUSTER}

kubectl config set-context --current --namespace=${NAMESPACE}
