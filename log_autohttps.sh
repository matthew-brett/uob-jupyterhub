# Log autohttps
. set_config.sh
# List pods
echo "Pods"
kubectl --namespace=$NAMESPACE get pod

echo "Proxy\n"
kubectl --namespace=$NAMESPACE get svc proxy-public

echo "Autohttps log"
kubectl logs pod/$(kubectl get pods -o custom-columns=POD:metadata.name | grep autohttps-) traefik -f
