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