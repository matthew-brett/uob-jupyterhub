# Set Kubernetes configuration

# Get variables
. vars.sh

# Reset cluster context, just in case
# Warning: Google Cloud specific; generalize in due course.
kubectl config use-context gke_${PROJECT_ID}_${REGION}_${JHUB_CLUSTER}

kubectl config set-context --current --namespace=${NAMESPACE}
