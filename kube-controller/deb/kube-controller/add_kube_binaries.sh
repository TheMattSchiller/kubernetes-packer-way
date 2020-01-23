#!/bin/bash
set -ex

# Versions
export KUBE_RELEASE=1.17.2

# Download kubernetes controller binaries
wget -q \
  "https://storage.googleapis.com/kubernetes-release/release/v${KUBE_RELEASE}/bin/linux/amd64/kube-apiserver" \
  "https://storage.googleapis.com/kubernetes-release/release/v${KUBE_RELEASE}/bin/linux/amd64/kube-controller-manager" \
  "https://storage.googleapis.com/kubernetes-release/release/v${KUBE_RELEASE}/bin/linux/amd64/kube-scheduler" \
  "https://storage.googleapis.com/kubernetes-release/release/v${KUBE_RELEASE}/bin/linux/amd64/kubectl"

# Create destination directory
mkdir -p debian/usr/local/bin

# Set permissions and move to /usr/local/bin
chmod +x kube-apiserver kube-controller-manager kube-scheduler kubectl
mv kube-apiserver kube-controller-manager kube-scheduler kubectl debian/usr/local/bin/
