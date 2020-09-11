#!/bin/bash
# Master script to setup, configure jupyterhub cluster
#
# Run after
#   source init_gcloud.sh
#   source init_kubernetes.sh
#   source setup_helm.sh
#
# Depends on:
# vars.sh
# config.yaml
source set_config.sh

# Apply Helm chart.
./rehelm.sh --install

# Show what's running
./show_pods.sh

echo Consider the following to reset https, if not correctly enabled.
echo ./log_autohttps.sh
echo ./reset_autohttps.sh
