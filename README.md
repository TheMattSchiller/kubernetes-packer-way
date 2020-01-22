# Kubernetes the Packer Way
This repo contains the source code and instructions for creating packer images created for the Kubernetes the Packer Way demo which is all about setting up a Kubernetes cluster using Packer, Terraform, Gradle, and CloudBuild to create a K8s cluster based on Kelsey Hightower's GitHub repo ["Kubernetes the Hard Way"](https://github.com/kelseyhightower/kubernetes-the-hard-way).

Read about the various topics here:

* [cloudbuild setup](cloudbuild.md)
* [gradle skeleton](gradle-skeleton/README.md)
* [kube-node gcp image made using packer](kube-node/README.md)
* [kube-controller gcp image made using packer](kube-controller/README.md)


Also don't forget to checkout the terraform example to see how we can deploy these images onto GCP and all the supporting infrastructure!

[Link to the terraform repo](https://github.com/TheMattSchiller/madebymatt-terraform)