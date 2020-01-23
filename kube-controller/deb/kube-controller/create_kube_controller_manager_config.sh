#!/bin/bash
set -ex

KUBERNETES_PUBLIC_ADDRESS=""
KUBE_DIR="debian/var/lib/kubernetes"

kubectl config set-cluster kubernetes \
  --certificate-authority=${KUBE_DIR}/ca.pem \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-credentials system:kube-controller-manager \
  --client-certificate=${KUBE_DIR}/controller-manager.pem \
  --client-key=${KUBE_DIR}/controller-manager-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-context default \
  --cluster=kubernetes \
  --user=system:kube-controller-manager \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig

mv kube-controller-manager.kubeconfig ${KUBE_DIR}/