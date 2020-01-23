#!/bin/bash
set -ex

KUBERNETES_PUBLIC_ADDRESS=""
KUBE_DIR="debian/var/lib/kubernetes"

kubectl config set-cluster kubernetes \
  --certificate-authority=${KUBE_DIR}/ca.pem \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config set-credentials system:kube-scheduler \
  --client-certificate=${KUBE_DIR}/scheduler.pem \
  --client-key=${KUBE_DIR}/scheduler-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config set-context default \
  --cluster=kubernetes \
  --user=system:kube-scheduler \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig

mv kube-scheduler.kubeconfig ${KUBE_DIR}/