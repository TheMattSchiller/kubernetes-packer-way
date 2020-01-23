#!/bin/bash

echo "Installing etcd package"
sudo dpkg -i /tmp/etcd*.deb

echo "Installing kubernetes control pane"
sudo dpkg -i /tmp/kube-controller*.deb