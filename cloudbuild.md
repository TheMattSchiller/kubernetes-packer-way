### GCP CloudBuild Setup

The images in this repo are built on GCP using [cloudbuild](https://cloud.google.com/cloud-build/), which creates a tarball of the packages and packer file and ships it to a docker container with [packer](https://www.packer.io/) installed on GCP, where it is built and converted to an image which we can then deploy. Lets start by setting up cloudbuild for GCP.

Enable the cloud API services for the project
```buildoutcfg
gcloud services enable sourcerepo.googleapis.com
gcloud services enable cloudapis.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable servicemanagement.googleapis.com
gcloud services enable storage-api.googleapis.com
gcloud services enable cloudbuild.googleapis.com
```
Enable the IAM policy for the cloudbuild service account
```buildoutcfg
CLOUD_BUILD_ACCOUNT=$(gcloud projects get-iam-policy $PROJECT --filter="(bindings.role:roles/cloudbuild.builds.builder)"  --flatten="bindings[].members" --format="value(bindings.members[])")

gcloud projects add-iam-policy-binding $PROJECT \
  --member $CLOUD_BUILD_ACCOUNT \
  --role roles/editor
```
Now we need to clone the cloudbuild repo
```buildoutcfg
git clone https://github.com/GoogleCloudPlatform/cloud-builders-community.git
```
Finally we will build the docker packer image by submitting it to gcloud builds
```buildoutcfg
cd cloud-builders-community/packer
gcloud builds submit .
```
[Back to main readme](/)