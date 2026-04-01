#!/bin/bash -e

[ "$provision_debug" = "true" ] && set -x

if [ "$provision_net_install" = "true" ]; then
  if [ -z $provision_k3s_binary_checksum ]; then
    echo "[Error] No checksum provided for k3s binary! Specify 'k3s_binary_checksum' in settings.yaml"
    exit 1
  fi

  # download k3s binary and verify checksum
  /vagrant/download_k3s.sh $provision_kubernetes_version $provision_k3s_binary_checksum
fi

# local install with official k3s get script
INSTALL_K3S_SKIP_DOWNLOAD=true K3S_TOKEN="$provision_token" /vagrant/get_k3s.sh