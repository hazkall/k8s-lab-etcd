Vagrant.configure("2") do |config|
  config.vm.box_check_update = true
  config.vm.provider 'virtualbox' do |v|
    v.customize [ "guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 1000 ]
  end
  $num_instances = 2
  (1..$num_instances).each do |i|
    config.vm.define "k8s-etcd-#{i}" do |k8s|
      k8s.vm.box = "centos/7"
      ip = "172.28.128.#{i+100}" 
      k8s.vm.hostname = "k8s-etcd-#{i}"
      (1..$num_instances).each do |i|
        k8s.vm.provision :shell, inline: "echo '172.28.128.#{i+100} k8s-etcd-#{i}' >> /etc/hosts"
      end
      k8s.vm.provision :shell, path: "install.sh"
      k8s.disksize.size = "10GB"
      k8s.vm.network :"private_network", ip: ip,
        auto_config: true
      k8s.vm.provider "virtualbox" do |v|
        v.customize ["modifyvm", :id, "--nicpromisc1", "allow-all", "--nicpromisc2", "allow-all"]
        v.memory = 2048
        v.cpus = 2
        v.name = "k8s-etcd-#{i}"
      end 
    end
  end
end

