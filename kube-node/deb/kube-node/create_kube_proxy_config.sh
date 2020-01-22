#!/bin/bash
set -ex

# Add your kubernetes public facing load balancer address here
KUBERNETES_PUBLIC_ADDRESS=""
KUBE_DIR="debian/var/lib/kubernetes"
KUBELET_DIR="debian/var/lib/kubelet"
KUBE_PROXY_DIR="debian/var/lib/kube-proxy/"

# The referenced certificates must be generated and added to the directories referenced!
kubectl config set-cluster kubernetes \
  --certificate-authority=${KUBE_DIR}/ca.pem \
  --embed-certs=true \
  --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config set-credentials system:kube-proxy \
  --client-certificate=${KUBE_PROXY_DIR}/kube-proxy.pem \
  --client-key=${KUBE_PROXY_DIR}/kube-proxy-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config set-context default \
  --cluster=kubernetes \
  --user=system:kube-proxy \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig

mv kube-proxy.kubeconfig ${KUBE_PROXY_DIR}/