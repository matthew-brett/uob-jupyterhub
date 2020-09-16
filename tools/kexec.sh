#!/bin/bash
pod=$1
if [ -z "$pod" ]; then
    echo "Pass pod name as argument"
    exit 1
fi
kubectl exec --stdin --tty $pod -- /bin/sh
