#!/bin/bash
set -ex

KUBERNETES_PUBLIC_ADDRESS="$1"
KUBE_DIR="debian/var/lib/kubernetes"

kubectl config set-cluster kubernetes \
  --certificate-authority=${KUBE_DIR}/ca.pem \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=admin.kubeconfig

kubectl config set-credentials admin \
  --client-certificate=${KUBE_DIR}/admin.pem \
  --client-key=${KUBE_DIR}/admin-key.pem \
  --embed-certs=true \
  --kubeconfig=admin.kubeconfig

kubectl config set-context default \
  --cluster=kubernetes \
  --user=admin \
  --kubeconfig=admin.kubeconfig

kubectl config use-context default --kubeconfig=admin.kubeconfig

mv admin.kubeconfig ${KUBE_DIR}/