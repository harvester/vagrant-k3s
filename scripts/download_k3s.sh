#!/bin/bash -eu
k3s_version=$1
k3s_binary_checksum=$2

[ "$provision_debug" = "true" ] && set -x

# download k3s binary and verify checksum
k3s_binary_url="https://github.com/k3s-io/k3s/releases/download/$provision_kubernetes_version/k3s"
echo "Downloading k3s binary from $k3s_binary_url"
curl -sL $k3s_binary_url -o /tmp/k3s
echo "$provision_k3s_binary_checksum  /tmp/k3s" | sha256sum -c -
echo "Checksum verification passed for k3s binary"
mv /tmp/k3s /usr/local/bin/ && chmod +x /usr/local/bin/k3s
