# Kube-controller packer template
This directory contains the packer template for creating a kubernetes controller instance image with the assistance of gradle. Packer can be used with CloudBuild on GCP in order to create images which we can the spin up as instances. Before creating this image make sure that the following guides have been followed:
* [CloudBuild](../cloudbuild.md)
* [Create an etcd package with Gradle](deb/etcd/)
* [Create a kube-controller package with Gradle](deb/kube-controller/)

# Scripts for Packer
There are many provisioners availible for Packer, but we will be using two of the most common and easy to use. These are the `shell` and `file` provisioners. We are going to tell packer to copy over our gradle packages first and then install them with the scripts we will now write. 

This next file will install and configure nginx for our `healthz` healthcheck, used by kubernetes to determine core service health. Our config file is already in place from the `kube-controller.deb` package

#### `configure_nginx.sh`
```
#!/bin/bash

# Install nginx
echo "Installing nginx"
sudo apt-get -y update && sudo apt-get -y install nginx

# Install the kubernetes healthcheck
sudo ln -s /etc/nginx/sites-available/kubernetes.default.svc.cluster.local \
  /etc/nginx/sites-enabled
sudo systemctl enable nginx
```
We will use the next script to install our `.deb` packages created with Gradle
#### `install_deb_packages.sh`
```
#!/bin/bash

echo "Installing etcd package"
sudo dpkg -i /tmp/etcd*.deb

echo "Installing kubernetes control pane"
sudo dpkg -i /tmp/kube-controller*.deb
```
Finally we will create our `kube-controler.packer` file which will provision our instance and create an image.

We need to fill in our `"project_id"` key value to match our project id in GCP
```
{
  "builders": [
    {
      "type": "googlecompute",
      "image_name": "kube-controller",
      "project_id": "",
      "source_image": "ubuntu-1804-bionic-v20200108",
      "ssh_username": "packer",
      "zone": "us-west1-a"
    }
  ],
  "provisioners": [
    {
      "type": "file",
      "source": "build/etcd*.deb",
      "destination": "/tmp/"
    },
    {
      "type": "file",
      "source": "build/kube-controller*.deb",
      "destination": "/tmp/"
    },
    {
      "type": "shell",
      "script": "configure_nginx.sh"
    },
    {
      "type": "shell",
      "script": "install_deb_pkgs.sh"
    }
  ]
}
```

# CloudBuild
We are going to run our packer build using cloudbuild, make sure to follow the [cloudbuild setup tutorial here](../cloudbuild.md).

Cloudbuild is going to run packer on GCP and needs all of the files and scripts we have referenced in our `kube-controller.packer` file, in addition to a few other.

The first of which is our `cloudbuild.yaml` file which will specify the following:

* `image_name` the name for our image in GCP
* `image_family` the family for our image, we are going to use `kubernetes`
* `image_zone` the zone to create our instance in (the resulting image will be available to our region)
#### `cloudbuild.yaml`
```
steps:
- name: 'gcr.io/$PROJECT_ID/packer'
  args:
  - build
  - -var
  - image_name=kube-controller
  - -var
  - image_family=kubernetes
  - -var
  - image_zone=us-west1-a
  - kube-controller.packer
```
We are going to create a helper script which will decend into our `deb/${package}` directories and build the package for each, then move it to a `build/` directory.
#### `build_pkgs.sh`
```
#!/bin/bash

PROJECT="$(pwd)"
PACKAGES="etcd kube-controller"
BUILD_DIR="build"

if [ ! -d "${BUILD_DIR}" ]; then
  echo "Making build dir"
  mkdir "${BUILD_DIR}"
fi

for PKG in $PACKAGES; do
  cd "deb/${PKG}" || exit 1
  sh build.sh
  mv build/distributions/*.deb "${PROJECT}/${BUILD_DIR}/"
  cd "${PROJECT}" || exit 1
done
```
We can use a `.gcloudignore` file to ensure that our deb directory is exluded which will drastically reduce the size and complexity of the archive we send up to cloudbuild
#### `.gcloudignore`
```
deb/*
```
*FINALLY*, one last helper script will make its so that we just need to run one command to build our packages and submit our archive to gcp so that packer can bake the instance.
#### `cloudbuild.sh`
```
#!/bin/bash
set -ex

# Build our packages with gradle
sh build_pkgs.sh

# Bake our image on gcp
gcloud builds submit

```
[Back to Kubernetes the Packer Way Readme](../)