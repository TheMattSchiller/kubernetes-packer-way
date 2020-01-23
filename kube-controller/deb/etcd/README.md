# Create an etcd package with Gradle
Kubernetes uses etcd as a highly available key: value store. It stores the configuration of the Kubernetes cluster in etcd. It also stores the actual state of the system and the desired state of the system in etcd.

This readme covers creation of an custom etcd package. Lets start by creating the folder structure for our package by copying our pre-created [gradle skeleton](https://github.com/TheMattSchiller/kubernetes-packer-way/tree/master/gradle_skeleton/README.md) into our etcd deb folder (this directory)

Now we will add the paths for our static files needed for etcd:
```
mkdir -p debian/etc/etcd
mkdir -p debian/etc/systemd/system
mkdir -p usr/local/bin
```
Now add the necessary certificates to the pki directory. See the [pki readme](https://github.com/TheMattSchiller/kubernetes-packer-way/tree/master/pki/)
```
cp ../../../pki/ca.pem ../../../pki/kubernetes.pem ../../../pki/kubernetes-key.pem pki/
```
Create the systemd service file
#### debian/etc/systemd/system/etcd.service
```
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
Type=notify
ExecStart=/bin/bash /etc/etcd/start-etcd.sh
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```
Create the systemd service script. This script is used to dynamically start the systemd service using the gcp metatdata for the instance ip as well as its hostname.
#### debian/etc/etcd/start-etcd.sh
```
#!/bin/bash

export INTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)

/usr/local/bin/etcd \
  --name ${HOSTNAME} \
  --cert-file=/etc/etcd/kubernetes.pem \
  --key-file=/etc/etcd/kubernetes-key.pem \
  --peer-cert-file=/etc/etcd/kubernetes.pem \
  --peer-key-file=/etc/etcd/kubernetes-key.pem \
  --trusted-ca-file=/etc/etcd/ca.pem \
  --peer-trusted-ca-file=/etc/etcd/ca.pem \
  --peer-client-cert-auth \
  --client-cert-auth \
  --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \
  --listen-peer-urls https://${INTERNAL_IP}:2380 \
  --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \
  --advertise-client-urls https://${INTERNAL_IP}:2379 \
  --initial-cluster-token etcd-cluster-0 \
  --initial-cluster kube-controller-0-ext-us-west1-a=https://10.5.2.10:2380,kube-controller-1-ext-us-west1-b=https://10.5.3.10:2380 \
  --initial-cluster-state new \
  --data-dir=/var/lib/etcds
```
Add execute permission to the `start-etcd.sh` script
```
chmod +x debian/etc/etcd/start-etcd.sh
```
Now we will create a script which will run on the host building the package which will download and install the etcd binaries
#### add_etcd_binary.sh
```
#!/bin/bash
set -ex

# Version
VERSION="v3.4.3"
ETCD="etcd-${VERSION}-linux-amd64"

# Download etcd binary
wget -q "https://github.com/etcd-io/etcd/releases/download/${VERSION}/${ETCD}.tar.gz"

# Make destination directory
mkdir -p debian/usr/local/bin

# Add to package
tar -xvf ${ETCD}.tar.gz
mv ${ETCD}/etcd* debian/usr/local/bin/
chmod +x debian/usr/local/bin/*

# Cleanup
rm -rf ${ETCD}.tar.gz ${ETCD}
```
We need a postinstall script to enable the etcd service
#### postinstall
```
#!/bin/bash

systemctl enable etcd
```
Finally we need to make a build.gradle file which will run our `add_etcd_binary.sh` script and add the contents of our package. This file runs our host script and then directs all of our static files and folders into the proper locations, then adds the postinstall script.
#### build.gradle
```
buildscript {
  repositories {
    jcenter()
    maven { url "https://plugins.gradle.org/m2" }
  }

  dependencies {
    classpath 'com.netflix.nebula:gradle-ospackage-plugin:4.7.0'
  }
}

apply plugin: 'nebula.ospackage'

task place_certificates(type:Exec) {
    workingDir '.'
    commandLine './place_certificates.sh'
}

task add_etcd_binary(type:Exec) {
    workingDir '.'
    commandLine './add_etcd_binary.sh'
}

task buildDebianArtifact(type:Deb) {
  packageName = "etcd"
  version = "1.0"
  release = 'bionic'

  dependsOn place_certificates
  dependsOn add_etcd_binary

  from ('debian/etc') {
      into ('/etc')
  }

  from ('debian/usr') {
      into ('/usr')
  }

  postInstallFile file('postinstall')
}
```
[Back to kube-controller packer template](https://github.com/TheMattSchiller/kubernetes-packer-way/tree/master/kube-controller)

[Back to Kubernetes the Packer Way Readme](https://github.com/TheMattSchiller/kubernetes-packer-way)