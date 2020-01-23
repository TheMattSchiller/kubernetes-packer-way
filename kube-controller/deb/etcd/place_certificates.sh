#!/bin/bash

# Place our already generated certificates in the proper directories
cp pki/ca.pem pki/kubernetes.pem pki/kubernetes-key.pem debian/etc/etcd/
