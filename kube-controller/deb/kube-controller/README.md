# Create the kube-controller package with Gradle
The kube-controller package will configure an instance to run the following Kubernetes binaries at startup

* [kube-apiserver](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/)
* [kube-controller-manager](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-controller-manager/)
* [kube-scheduler](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-scheduler/)

This will allow our kube-controller instaces to recieve api calls and to manage the state of our kubernetes cluster. These binaires are explained more in depth on the kubernetes documentation links provided above.

# PKI
First lets make add our required certifictates into the pki directory
```
cp ../../../pki/ca.pem \
  ../../../pki/kubernetes.pem \
  ../../../pki/kubernetes-key.pem \
  ../../../pki/admin.pem \
  ../../../pki/admin-key.pem \
  ../../../pki/scheduler.pem \
  ../../../pki/scheduler-key.pem \
  ../../../pki/service-account.pem \
  ../../../pki/service-account-key.pem \
  pki/
```
We need to create the directory structure to contain our static files
```
mkdir -p debian/var/lib/kubernetes \
  debian/etc/kubernetes/config \
  debian/etc/nginx/sites-available \
  debian/etc/systemd/system
```

# Systemd Service Files
Now we will create the systemd service files.

## kube-apiserver.service
Note that we want the kube-apiserver to start after the `etcd.service` as it is dependent on this service
#### debian/etc/systemd/system/kube-apiserver.service
```
[Unit]
Description=Kubernetes API Server
Documentation=https://kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/
After=etcd.service

[Service]
ExecStart=/bin/bash /etc/kubernetes/start-kube-apiserver.sh
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```
kube-apiserver will use startup script to keep the service file cleaner and to make it easy to dynamically assign variables based on the indivdual instance running the service. This file needs to have the `--etcd-servers` and `--service-cluster-ip-range` parametes customized to the values of your cluster.
* `--etcd-servers` needs to have the https address of each kube-controller in your cluster.
* `--service-cluster-ip-range` needs to have the ip range which kubernetes will use to create [services](https://kubernetes.io/docs/concepts/services-networking/service/) on.

```
#!/bin/bash

/usr/local/bin/kube-apiserver \
  --advertise-address=0.0.0.0 \
  --allow-privileged=true \
  --apiserver-count=2 \
  --audit-log-maxage=30 \
  --audit-log-maxbackup=3 \
  --audit-log-maxsize=100 \
  --audit-log-path=/var/log/audit.log \
  --authorization-mode=Node,RBAC \
  --bind-address=0.0.0.0 \
  --client-ca-file=/var/lib/kubernetes/ca.pem \
  --enable-admission-plugins=NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \
  --etcd-cafile=/var/lib/kubernetes/ca.pem \
  --etcd-certfile=/var/lib/kubernetes/kubernetes.pem \
  --etcd-keyfile=/var/lib/kubernetes/kubernetes-key.pem \
  --etcd-servers=https://10.5.2.10:2379,https://10.5.3.10:2379 \
  --event-ttl=1h \
  --encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \
  --kubelet-certificate-authority=/var/lib/kubernetes/ca.pem \
  --kubelet-client-certificate=/var/lib/kubernetes/kubernetes.pem \
  --kubelet-client-key=/var/lib/kubernetes/kubernetes-key.pem \
  --kubelet-https=true \
  --runtime-config=api/all=true \
  --service-account-key-file=/var/lib/kubernetes/service-account.pem \
  --service-cluster-ip-range=10.32.0.0/24 \
  --service-node-port-range=30000-32767 \
  --tls-cert-file=/var/lib/kubernetes/kubernetes.pem \
  --tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \
  --v=2
  ```

## kube-controller-manager.service
  Lets move on to the `kube-controller-manager` service. This one is pretty straight forward we just need to make sure that the following variables are set properly for our cluster:
  * `--cluster-cidr` needs to be set to the cidr of our cluster, this is the ip range where pods will be assigned (and each node will have a cidr for pods within this cluster cidr)
 * `--service-cluster-ip-range` needs to have the ip range which kubernetes will use to create [services](https://kubernetes.io/docs/concepts/services-networking/service/) on
#### debian/etc/systemd/system/kube-controller-manager.service
```
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes
After=kube-apiserver.service

[Service]
ExecStart=/usr/local/bin/kube-controller-manager \
  --address=0.0.0.0 \
  --cluster-cidr=10.6.0.0/16 \
  --cluster-name=kubernetes \
  --cluster-signing-cert-file=/var/lib/kubernetes/ca.pem \
  --cluster-signing-key-file=/var/lib/kubernetes/ca-key.pem \
  --kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \
  --leader-elect=true \
  --root-ca-file=/var/lib/kubernetes/ca.pem \
  --service-account-private-key-file=/var/lib/kubernetes/service-account-key.pem \
  --service-cluster-ip-range=10.32.0.0/24 \
  --use-service-account-credentials=true \
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

## kube-scheduler.service
Now we will create the kube-scheduler service file. This one is the most simple and we will create its config in a later step
#### debian/etc/systemd/system/kube-scheduler.service
```
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-scheduler \
  --config=/etc/kubernetes/config/kube-scheduler.yaml \
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```
We also need the config file for `kube-scheduler`
#### debian/etc/kubernetes/config/kube-scheduler.yaml
```
apiVersion: kubescheduler.config.k8s.io/v1alpha1
kind: KubeSchedulerConfiguration
clientConnection:
  kubeconfig: "/var/lib/kubernetes/kube-scheduler.kubeconfig"
leaderElection:
  leaderElect: true
```

## kube-rbac.service
Once our kube-controller is running we are going to need to read our role binding so that our nodes can register with the cluster. This is going to require making a few files containing the [ClusterRole and ClusterRoleBinding](https://kubernetes.io/docs/reference/access-authn-authz/rbac/). Then we will create a script to run `kubectl` using the files, and finally call them after the `kube-apiserver` starts.
#### debian/var/lib/kubernetes/kube-apiserver-to-kubelet-role
```
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: system:kube-apiserver-to-kubelet
rules:
  - apiGroups:
      - ""
    resources:
      - nodes/proxy
      - nodes/stats
      - nodes/log
      - nodes/spec
      - nodes/metrics
    verbs:
      - "*"
```
#### debian/var/lib/kubernetes/kube-apiserver-to-kubelet-bind
```
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: system:kube-apiserver
  namespace: ""
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:kube-apiserver-to-kubelet
subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: kubernetes
```
#### debian/etc/kubernetes/kube-rbac.sh
This will be our service startup script and needs to have execute permission added
```
#!/bin/bash

KUBE_DIR="/var/lib/kubernetes"

# Wait for kube-apiserver to complete startup
sleep 20

kubectl apply --kubeconfig ${KUBE_DIR}/admin.kubeconfig -f ${KUBE_DIR}/kube-apiserver-to-kubelet-role
kubectl apply --kubeconfig ${KUBE_DIR}/admin.kubeconfig -f ${KUBE_DIR}/kube-apiserver-to-kubelet-bind
```
```
$ chmod +x debian/etc/kubernetes/kube-rbac.sh
```
#### debian/etc/systemd/system/kube-rbac.service
```
[Unit]
Description=Setup Role Binding
After=kube-controller-manager.service
After=kube-apiserver.service

[Service]
Type=oneshot
ExecStart=/bin/bash /etc/kubernetes/kube-rbac.sh

[Install]
WantedBy=multi-user.target
```
#### postinstall
Now is a good time to create our `postinstall` script which will enable the services we just created after the package is installed
```
#!/bin/bash

# enable service
systemctl enable kube-apiserver kube-controller-manager kube-scheduler kube-config
```

# Generate kubecconfig scripts
The following scripts we will create in order to generate our `.kubeconfig` files for each of the `kube-controller` components.
#### create_admin_config.sh
We need to add the `KUBERNETES_PUBLIC_ADDRESS` which matches the load balander ip for our cluster, and the admin cert/keys need to be in our `/var/lib/kubernetes` directory.
```
#!/bin/bash
set -ex

KUBERNETES_PUBLIC_ADDRESS=""
KUBE_DIR="debian/var/lib/kubernetes"

kubectl config set-cluster kubernetes \
  --certificate-authority=${KUBE_DIR}/ca.pem \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=admin.kubeconfig

kubectl config set-credentials admin \
  --client-certificate=${KUBE_DIR}/admin.pem \
  --client-key=${KUBE_DIR}/admin-key.pem \
  --embed-certs=true \
  --kubeconfig=admin.kubeconfig

kubectl config set-context default \
  --cluster=kubernetes \
  --user=admin \
  --kubeconfig=admin.kubeconfig

kubectl config use-context default --kubeconfig=admin.kubeconfig

mv admin.kubeconfig ${KUBE_DIR}/
```
#### create_kube_controller_manager_config.sh
We need to add the `KUBERNETES_PUBLIC_ADDRESS` which matches the load balander ip for our cluster, and the admin cert/keys need to be in our `/var/lib/kubernetes` directory.
```
#!/bin/bash
set -ex

KUBERNETES_PUBLIC_ADDRESS=""
KUBE_DIR="debian/var/lib/kubernetes"

kubectl config set-cluster kubernetes \
  --certificate-authority=${KUBE_DIR}/ca.pem \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-credentials system:kube-controller-manager \
  --client-certificate=${KUBE_DIR}/controller-manager.pem \
  --client-key=${KUBE_DIR}/controller-manager-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-context default \
  --cluster=kubernetes \
  --user=system:kube-controller-manager \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig

mv kube-controller-manager.kubeconfig ${KUBE_DIR}/
```
#### create_kube_scheduler_config.sh
We need to add the `KUBERNETES_PUBLIC_ADDRESS` which matches the load balander ip for our cluster, and the admin cert/keys need to be in our `/var/lib/kubernetes` directory.
```
#!/bin/bash
set -ex

KUBERNETES_PUBLIC_ADDRESS=""
KUBE_DIR="debian/var/lib/kubernetes"

kubectl config set-cluster kubernetes \
  --certificate-authority=${KUBE_DIR}/ca.pem \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config set-credentials system:kube-scheduler \
  --client-certificate=${KUBE_DIR}/scheduler.pem \
  --client-key=${KUBE_DIR}/scheduler-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config set-context default \
  --cluster=kubernetes \
  --user=system:kube-scheduler \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig

mv kube-scheduler.kubeconfig ${KUBE_DIR}/
```
#### create_encryption_config.sh
This script will create our enryption config by generating a random base64 string, adding it into an [EncryptionConfig](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/) file which will be used to encrypt data at rest in our cluster. This file is used by the `kube-apiserver` and is passed into its startup with the`--encryption-provider-config`
```
#!/bin/bash
set -ex

# Create encryption key
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)

# Create encryption config
cat > encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF

# Move to location
mv encryption-config.yaml debian/var/lib/kubernetes/
```

# Add kubernetes binaries script
This script will download the kubernetes binaries for `$KUBE_RELEASE` version, change thier permissions, and add them to the `/usr/local/bin` folder
```
#!/bin/bash
set -ex

# Versions
export KUBE_RELEASE=1.17.2

# Download kubernetes controller binaries
wget -q \
  "https://storage.googleapis.com/kubernetes-release/release/v${KUBE_RELEASE}/bin/linux/amd64/kube-apiserver" \
  "https://storage.googleapis.com/kubernetes-release/release/v${KUBE_RELEASE}/bin/linux/amd64/kube-controller-manager" \
  "https://storage.googleapis.com/kubernetes-release/release/v${KUBE_RELEASE}/bin/linux/amd64/kube-scheduler" \
  "https://storage.googleapis.com/kubernetes-release/release/v${KUBE_RELEASE}/bin/linux/amd64/kubectl"

# Create destination directory
mkdir -p debian/usr/local/bin

# Set permissions and move to /usr/local/bin
chmod +x kube-apiserver kube-controller-manager kube-scheduler kubectl
mv kube-apiserver kube-controller-manager kube-scheduler kubectl debian/usr/local/bin/
```

# Healthz healthcheck nginx config file
Packer is going to install nginx and this is a fine of place as any to put our nginx config file which we will link after installing nginx. We cannot call `apt` to install during a `dpkg` install so we will do that with a step in packer. If we were using a apt repository we would be able to have dependencies but since we are doing a standalone package install we are just going to install dependencies with packer.
#### debian/etc/nginx/sites-available/kubernetes.default.svc.cluster.local
```
server {
  listen      80;
  server_name kubernetes.default.svc.cluster.local;

  location /healthz {
     proxy_pass                    https://127.0.0.1:6443/healthz;
     proxy_ssl_trusted_certificate /var/lib/kubernetes/ca.pem;
  }
}
```

# Gradle build
#### build.gradle
Finally we just need to create our `build.gradle` file which will run all of our build scripts and package our `debian/` directory into a `kube-controller.deb` with our postinstall script.

Notice that each of our build scripts are referenced as an exec task, these create all of our configs and download all of the binaries adding them to the correct directories in `debian/` directory.

Our `buildDebianArtifact` task has a `dependsOn` directive for each of the exec tasks. Then several 'from' statements to add our folders in `/debian` to the required paths on the system installing the package. Finally the `postinstall` script is added into a `postInstallFile` method which will run on the system after all of the files from the package are in place.
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

task create_kube_scheduler_config(type:Exec) {
    workingDir '.'
    commandLine './create_kube_scheduler_config.sh'
}

task create_kube_controller_manager_config(type:Exec) {
    workingDir '.'
    commandLine './create_kube_controller_manager_config.sh'
}

task create_admin_config(type:Exec) {
    workingDir '.'
    commandLine './create_admin_config.sh'
}

task add_kube_binaries(type:Exec) {
    workingDir '.'
    commandLine './add_kube_binaries.sh'
}

task create_encryption_config(type:Exec) {
    workingDir '.'
    commandLine './create_encryption_config.sh'
}

task buildDebianArtifact(type:Deb) {
  packageName = "kube-controller"
  version = "1.0"
  release = 'bionic'

  dependsOn create_kube_scheduler_config
  dependsOn create_kube_controller_manager_config
  dependsOn create_admin_config
  dependsOn add_kube_binaries
  dependsOn create_encryption_config

  from ('debian/etc') {
      into ('/etc')
  }

  from ('debian/usr') {
      into ('/usr')
  }

  from ('debian/var') {
      into ('/var')
  }

  postInstallFile file('postinstall')
}
```
