# Kubernetes the Packer Way
This repo contains the source code and instructions for creating packer images created for the Kubernetes the Packer Way demo which is all about setting up a Kubernetes cluster using Packer, Terraform, Gradle, and CloudBuild to create a K8s cluster based on Kelsey Hightower's GitHub repo ["Kubernetes the Hard Way"](https://github.com/kelseyhightower/kubernetes-the-hard-way).

Read about the various topics and see a tutorial of the code here:

* [cloudbuild setup](cloudbuild.md)
* [gradle skeleton](https://github.com/TheMattSchiller/kubernetes-packer-way/tree/master/gradle-skeleton)
* [kube-controller gcp image made using packer](https://github.com/TheMattSchiller/kubernetes-packer-way/tree/master/kube-controller)
* [kube-node gcp image made using packer](kube-node/) (tutorial development in-progress)

Also don't forget to checkout the terraform example to see how we can deploy these images onto GCP and all the supporting infrastructure!

[Link to the terraform repo](https://github.com/TheMattSchiller/madebymatt-terraform)