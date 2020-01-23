#!/bin/bash

KUBE_DIR="/var/lib/kubernetes"

# Wait for kube-apiserver to complete startup
sleep 20

kubectl apply --kubeconfig ${KUBE_DIR}/admin.kubeconfig -f ${KUBE_DIR}/kube-apiserver-to-kubelet-role
kubectl apply --kubeconfig ${KUBE_DIR}/admin.kubeconfig -f ${KUBE_DIR}/kube-apiserver-to-kubelet-bind