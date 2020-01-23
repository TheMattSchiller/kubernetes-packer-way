#!/bin/bash

# Install nginx
echo "Installing nginx"
sudo apt-get -y update && sudo apt-get -y install nginx

# Install the kubernetes healthcheck
sudo ln -s /etc/nginx/sites-available/kubernetes.default.svc.cluster.local \
  /etc/nginx/sites-enabled
sudo systemctl enable nginx