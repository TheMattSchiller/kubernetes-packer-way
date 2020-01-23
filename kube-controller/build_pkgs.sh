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

