# vagrant-k3s

Create a k3s cluster with Vagrant (libvirt provider) in no time.

## Requirements

- Vagrant
- Vagrant-libvirt
- `yq` and `kubectl` on the host.

## Quick start


1. Edit `settings.yaml`:

    ```yaml
    # A k3s version. Check https://github.com/k3s-io/k3s/releases
    kubernetes_version: v1.35.2+k3s1

    # SHA256 checksum of the k3s binary for the specified version
    # For example, check assets tree in the release https://github.com/k3s-io/k3s/releases/tag/v1.35.2%2Bk3s1
    k3s_binary_checksum: 3ae8e35a62ac83e8e197c117858a564134057a7b8703cf73e67ce60d19f4a22b

    # SHA256 checksum of the k3s install script for the specified version
    # For example: https://github.com/k3s-io/k3s/blob/v1.35.2%2Bk3s1/install.sh.sha256sum
    k3s_install_checksum: 8598e002e61d658fed7b7542fc6d2c66d8da6eae69e088830105d2ee1ffb6d91
    
    # Change to something secret.
    token: sometoken

    # Default to 3 nodes. First node is server node and the others are agent nodes.
    cluster_size: 3
    ```

    **Important:** You must specify the `k3s_binary_checksum` and `k3s_install_checksum` for your chosen k3s version before starting the cluster. These checksums ensure the downloaded k3s binary and install script haven't been tampered with.

2. Create the cluster.

    ```
    ./new-cluster.sh
    ```

    If everything goes right, a file `kubeconfig` is generated:

    ```
    # export KUBECONFIG=$(pwd)/kubeconfig
    # kubectl get nodes
    ```

3. Tear down the cluster.

   ```
   vagrant destroy
   ```
