#!/bin/bash
set -ex

# Versions of binaries to download
export CRICTL=1.17.0
export RUNC=1.0.0-rc9
export CNI=0.8.4
export CONTAINERD=1.3.2
export KUBE_RELEASE=1.17.2

# Download all binaries to create a
wget -q \
  https://github.com/kubernetes-sigs/cri-tools/releases/download/v${CRICTL}/crictl-v${CRICTL}-linux-amd64.tar.gz \
  https://github.com/opencontainers/runc/releases/download/v${RUNC}/runc.amd64 \
  https://github.com/containernetworking/plugins/releases/download/v${CNI}/cni-plugins-linux-amd64-v${CNI}.tgz \
  https://github.com/containerd/containerd/releases/download/v${CONTAINERD}/containerd-${CONTAINERD}.linux-amd64.tar.gz \
  https://storage.googleapis.com/kubernetes-release/release/v${KUBE_RELEASE}/bin/linux/amd64/kubectl \
  https://storage.googleapis.com/kubernetes-release/release/v${KUBE_RELEASE}/bin/linux/amd64/kube-proxy \
  https://storage.googleapis.com/kubernetes-release/release/v${KUBE_RELEASE}/bin/linux/amd64/kubelet

# Create directories for binaries
mkdir -p \
  debian/opt/cni/bin \
  debian/var/run/kubernetes \
  debian/usr/local/bin \
  debian/bin \

# Set permissions and move to binaries to respective locations
mv runc.amd64 runc
chmod +x kubectl kube-proxy kubelet runc
mv kubectl kube-proxy kubelet runc debian/usr/local/bin/
tar -xvf crictl-v${CRICTL}-linux-amd64.tar.gz -C debian/usr/local/bin/
tar -xvf cni-plugins-linux-amd64-v${CNI}.tgz -C debian/opt/cni/bin/
tar -xvf containerd-${CONTAINERD}.linux-amd64.tar.gz -C debian/

# Cleanup
rm -rf crictl-v${CRICTL}-linux-amd64.tar.gz \
  cni-plugins-linux-amd64-v${CNI}.tgz \
  containerd-${CONTAINERD}.linux-amd64.tar.gz