#!/bin/sh
. vars.sh
kubectl get pod --namespace $NAMESPACE
kubectl get service --namespace $NAMESPACE
