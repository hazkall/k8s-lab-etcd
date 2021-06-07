#!/bin/bash
set -ex

whoami

sudo yum update -y
sudo yum upgrade -y
sudo yum install -y vim telnet strace


# Set SELinux in permissive mode (effectively disabling it)
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

sudo systemctl stop firewalld
sudo systemctl disable firewalld

sudo swapoff -a
sudo sed -i 's/.*swap.*/#&/' /etc/fstab

#Install CRI-O v1.19

if [ ! -d /etc/modules-load.d/ ]; 
    then
        sudo mkdir -p /etc/modules-load.d
fi

cat <<EOF | sudo tee /etc/modules-load.d/crio.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter


cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system

export OS=CentOS_7
export VERSION=1.21

sudo curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/devel:kubic:libcontainers:stable.repo
sudo curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.repo https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/$OS/devel:kubic:libcontainers:stable:cri-o:$VERSION.repo
sudo yum install -y cri-o


if [ ! -d /etc/crio/crio.conf.d/ ]; 
    then
        sudo mkdir -p /etc/crio/crio.conf.d/ 
fi

cat <<EOF | sudo tee /etc/crio/crio.conf.d/02-cgroup-manager.conf
[crio.runtime]
conmon_cgroup = "pod"
cgroup_manager = "systemd"
EOF


sudo systemctl daemon-reload
sudo systemctl enable crio --now

#Install Kubernetes v1.21

cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

sudo yum install -y kubelet-1.21.1 kubeadm-1.21.1 kubectl-1.21.1 --disableexcludes=kubernetes

sudo systemctl enable --now kubelet

cat <<EOF | sudo tee /tmp/kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
kubernetesVersion: 1.21.1
controlPlaneEndpoint: "$(uname -n):6443"
networking:
  podSubnet: 192.168.0.0/16
  serviceSubnet: 10.96.0.0/12
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
---
apiVersion: kubeadm.k8s.io/v1beta2
kind: InitConfiguration
nodeRegistration:
  criSocket: "unix:///var/run/crio/crio.sock"
EOF

if [ ! -d /etc/NetworkManager/conf.d/]; 
    then
        sudo mkdir -p /etc/NetworkManager/conf.d/
fi


cat <<EOF | sudo tee /etc/NetworkManager/conf.d/calico.conf
[keyfile]
unmanaged-devices=interface-name:cali*;interface-name:tunl*;interface-name:vxlan.calico
EOF

if [ "$HOSTNAME" = k8s-etcd-1 ]; 
  then
        sudo kubeadm config images pull
        sudo kubeadm init --config=/tmp/kubeadm-config.yaml --upload-certs | tee /tmp/kubeadm.out
          mkdir -p /home/vagrant/.kube
          sudo cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
          sudo chown vagrant:vagrant /home/vagrant/.kube/config
          kubectl create -f https://docs.projectcalico.org/manifests/tigera-operator.yaml --kubeconfig=/etc/kubernetes/admin.conf
          kubectl create -f https://docs.projectcalico.org/manifests/custom-resources.yaml --kubeconfig=/etc/kubernetes/admin.conf
fi