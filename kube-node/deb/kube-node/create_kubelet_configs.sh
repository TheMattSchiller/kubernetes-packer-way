#!/bin/bash
set -ex

# Add your kubernetes public facing load balancer address here
KUBERNETES_PUBLIC_ADDRESS=""
INSTANCES="kube-node-0-ext-us-west1-a kube-node-1-ext-us-west1-b"
KUBE_DIR="debian/var/lib/kubernetes"
KUBELET_DIR="debian/var/lib/kubelet"

# The referenced certificates must be generated and added to the directories referenced!
for instance in $INSTANCES; do
  kubectl config set-cluster kubernetes \
    --certificate-authority=${KUBE_DIR}/ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
    --kubeconfig=${instance}.kubeconfig

  kubectl config set-credentials system:node:${instance} \
    --client-certificate=${KUBELET_DIR}/${instance}.pem \
    --client-key=${KUBELET_DIR}/${instance}-key.pem \
    --embed-certs=true \
    --kubeconfig=${instance}.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes \
    --user=system:node:${instance} \
    --kubeconfig=${instance}.kubeconfig

  kubectl config use-context default --kubeconfig=${instance}.kubeconfig
  mv ${instance}.kubeconfig ${KUBELET_DIR}/${instance}.kubeconfig
done