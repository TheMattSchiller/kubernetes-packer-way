#!/bin/bash
set -ex

sh build_pkgs.sh
gcloud builds submit

