# Source this file.
HUB_NAME=uobhub
echo "Configuration for hub ${HUB_NAME}"
# Common config, overwritten by specific config below.
source vars.sh.common
# Specific config for this hub.
source hubs/vars.sh.${HUB_NAME}
# Config; this one will often have secrets.
CONFIG_YAML=jh-secrets/config.yaml.${HUB_NAME}
# 12GB default machine.
DEFAULT_MACHINE=n1-custom-2-12288
