# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.provider :virtualbox do |vb|
     # Don't boot with headless mode
     vb.gui = false
     # Use VBoxManage to customize the VM. For example to change memory:
     vb.customize ["modifyvm", :id, "--memory", "1024"]
  end
  config.vm.define :centos do |centos|
    centos.vm.box = "centos65-x64"
    centos.vm.network :private_network, ip: "192.168.50.10"
    centos.vm.network :forwarded_port, guest: 3000, host: 3000
    centos.vm.network :forwarded_port, guest: 8140, host: 8140
    #centos.vm.synced_folder "hieradata", "/etc/puppet/hieradata"
    #centos.vm.synced_folder "~/.ssh", "/root/.ssh"
    #centos.vm.synced_folder "modules/modules", "/etc/puppet/modules"
    #centos.vm.synced_folder "modules/manifests", "/etc/puppet/manifests"
    #centos.vm.provision :shell, :path => "agent-setup.sh", :args => "centos"
    #centos.vm.provision :shell, :path => "puppetbooty.sh", :args => "--type master --hostname master"
  end

  config.vm.define :centos_agent do |centos_agent|
    centos_agent.vm.box = "centos65-x64"
    centos_agent.vm.network :private_network, ip: "192.168.50.11"
    centos_agent.vm.provision :shell, :path => "puppetbooty.sh", :args => "--type agent --master 192.168.50.10 --hostname centos_agent --proxy"
  end
end
