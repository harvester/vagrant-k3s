#!/bin/bash -e

[ "$provision_debug" = "true" ] && set -x

if [ -z "$provision_k3s_binary_checksum" ]; then
  echo "[Error] No checksum provided for k3s binary! Specify 'k3s_binary_checksum' in settings.yaml"
  exit 1
fi

if [ -z "$provision_k3s_install_checksum" ]; then
  echo "[Error] No checksum provided for k3s install script! Specify 'k3s_install_checksum' in settings.yaml"
  exit 1
fi

# download k3s binary and verify checksum
/vagrant/download_k3s.sh "$provision_kubernetes_version" "$provision_k3s_binary_checksum"

# download k3s install script and verify checksum
/vagrant/download_k3s_installer.sh "$provision_kubernetes_version" "$provision_k3s_install_checksum"

# install with downloaded k3s install script
INSTALL_K3S_SKIP_DOWNLOAD=true K3S_TOKEN="$provision_token" /tmp/k3s_install.sh