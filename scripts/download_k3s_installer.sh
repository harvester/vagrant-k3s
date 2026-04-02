#!/bin/bash -eu
k3s_version=$1
k3s_install_checksum=$2

[ "$provision_debug" = "true" ] && set -x

# download k3s install script and verify checksum
k3s_install_url="https://raw.githubusercontent.com/k3s-io/k3s/$provision_kubernetes_version/install.sh"
echo "Downloading k3s install script from $k3s_install_url"
curl -sL $k3s_install_url -o /tmp/k3s_install.sh
echo "$provision_k3s_install_checksum  /tmp/k3s_install.sh" | sha256sum -c -
echo "Checksum verification passed for k3s install script"
chmod +x /tmp/k3s_install.sh
