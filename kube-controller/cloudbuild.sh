#!/bin/bash
set -ex

# Build our packages with gradle
sh build_pkgs.sh

# Bake our image on gcp
gcloud builds submit
