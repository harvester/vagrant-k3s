#!/bin/bash -e

TOP_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." &> /dev/null && pwd )"

WORK_DIR="$TOP_DIR/workdir"
ARCH=$(uname -m)
if [[ $ARCH == "x86_64" ]]; then
  ARCH=amd64
elif [[ $ARCH == "aarch64" ]]; then
  ARCH=arm64
else
  echo "Unsupported architecture: $ARCH"
  exit 1
fi

# global variables
HELM=""

ensure_command() {
  local cmd=$1
  if ! which $cmd &> /dev/null; then
    echo 1
    return
  fi
  echo 0
}

ensure_helm() {
  HELM_VERSION=v3.20.0
  HELM_SUM_amd64=dbb4c8fc8e19d159d1a63dda8db655f9ffa4aac1b9a6b188b34a40957119b286
  HELM_SUM_arm64=bfb14953295d5324d47ab55f3dfba6da28d46c848978c8fbf412d4271bdc29f1
  HELM_SUM="HELM_SUM_${ARCH}"

  if [[ $(ensure_command helm) -eq 1 ]]; then
    echo "no helm, try to curl..."
    readonly helm_dir="${WORK_DIR}/.helm"

    mkdir -p $helm_dir
    pushd "$helm_dir" > /dev/null
    curl -O https://get.helm.sh/helm-${HELM_VERSION}-linux-${ARCH}.tar.gz 
    echo "${!HELM_SUM}" helm-${HELM_VERSION}-linux-${ARCH}.tar.gz | sha256sum -c -
    tar xvzf helm-${HELM_VERSION}-linux-${ARCH}.tar.gz --strip-components=1
    HELM="${helm_dir}/helm"
    $HELM version
    popd > /dev/null
  else
    echo "Get helm, version info as below"
    HELM=$(which helm)
    $HELM version
  fi
}

wait_longhorn_ready() {

  # ensure longhorn-manager first
  while [ true ]; do
    running_num=$(kubectl get pods -n longhorn-system |grep ^longhorn-manager |grep Running |awk '{print $3}' |wc -l)
    if [[ $running_num -eq ${cluster_nodes} ]]; then
      echo "longhorn-manager pods are ready!"
      break
    fi
    echo "longhorn-manager ready number: $running_num"
    echo "sleeping 10 seconds"
    sleep 10
  done

  # longhorn v1.5.0 and later version do not have instance-manager-e/instance-manager-r
  # Checking the instance-manager
  if [[ ${longhorn_version} == "1.5.0" || ${longhorn_version} > "1.5.0" ]]; then
    while [ true ]; do
      running_num=$(kubectl get pods -n longhorn-system |grep ^instance-manager |grep Running |awk '{print $3}' |wc -l)
      if [[ $running_num -eq ${cluster_nodes} ]]; then
        echo "instance-manager pods are ready!"
        break
      fi
      echo "instance-manager ready number: $running_num"
      echo "sleeping 10 seconds"
      sleep 10
    done
  else
    # v1.4.x and berfore version
    # ensure instance-manager-e ready
    while [ true ]; do
      running_num=$(kubectl get pods -n longhorn-system |grep ^instance-manager-e |grep Running |awk '{print $3}' |wc -l)
      if [[ $running_num -eq ${cluster_nodes} ]]; then
        echo "instance-manager-e pods are ready!"
        break
      fi
      echo "instance-manager-e ready number: $running_num"
      echo "sleeping 10 seconds"
      sleep 10
    done

    # ensure instance-manager-r ready
    while [ true ]; do
      running_num=$(kubectl get pods -n longhorn-system |grep ^instance-manager-r |grep Running |awk '{print $3}' |wc -l)
      if [[ $running_num -eq ${cluster_nodes} ]]; then
        echo "instance-manager-r pods are ready!"
        break
      fi
      echo "instance-manager-r ready number: $running_num"
      echo "sleeping 10 seconds"
      sleep 10
    done
  fi
}

if [ ! -f $TOP_DIR/kubeconfig ]; then
  echo "kubeconfig does not exist. Please create cluster first."
  echo "Maybe try new_cluster.sh"
  exit 1
fi
export KUBECONFIG=$TOP_DIR/kubeconfig

ensure_helm

longhorn_version=$(yq -e e '.longhorn_version' $TOP_DIR/settings.yaml)
echo Target Longhorn version: $longhorn_version
cluster_nodes=$(yq -e e '.cluster_size' $TOP_DIR/settings.yaml)
echo "cluster nodes: $cluster_nodes"

mkdir -p $WORK_DIR
pushd $WORK_DIR > /dev/null
# cleanup first
rm -rf longhorn

# pull longhorn
$HELM pull longhorn --repo https://charts.longhorn.io --version ${longhorn_version} --untar

$HELM install longhorn ./longhorn --create-namespace -n longhorn-system

wait_longhorn_ready
kubectl get pods -n longhorn-system
echo "longhorn is ready"
popd > /dev/null
