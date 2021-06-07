# Lab to create machines (training with ETCD)

Before start vagrant, you can change the follow configs.

On Vagrantfile

```sh

Vagrant.configure("2") do |config|
  config.vm.box_check_update = true
  config.vm.provider 'virtualbox' do |v|
    v.customize [ "guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 1000 ]
  end
  $num_instances = # <- Insert Here the number of machines to create.

```

On Shellscript install.sh

```sh
sudo sysctl --system

export OS=CentOS_7 # <- Insert here the version of S.O
export VERSION=1.21 # <- Insert here the version of CRI-O, this need match with the Kubernetes version


sudo curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/devel:kubic:libcontainers:stable.repo
sudo curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.repo https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/$OS/devel:kubic:libcontainers:stable:cri-o:$VERSION.repo
sudo yum install -y cri-o

```

With all configurations ok, just run

```sh

vagrant up

```

On master node, you will need to get the output of kubeadm to join the workers nod

```sh
#Enter on worker node
vagrant ssh k8s-etcd-2

cat /tmp/kubeadm.out | tail -n2

# Now get the join command and use on worker nodes.

```