#!/bin/sh
# Log autohttps
. set_config.sh

# List pods
./show_pods.sh

echo "Autohttps log"
kubectl logs pod/$(kubectl get pods -o custom-columns=POD:metadata.name | grep autohttps-) traefik -f
