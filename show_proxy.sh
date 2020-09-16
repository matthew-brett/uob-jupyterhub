#!/bin/sh
. vars.sh
kubectl --namespace=$NAMESPACE get svc proxy-public
