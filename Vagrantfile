# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  # Every Vagrant virtual environment requires a box to build off of.
  #config.vm.box = "base-sles-11.2-x64-1.0"

  # The url from where the 'config.vm.box' box will be fetched if it
  # doesn't already exist on the user's system.
  #config.vm.box_url = "http://ntlvmbsm01.nibdom.com.au/vagrant/base-sles-11.2-x64-1.0.box"

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # config.vm.network :forwarded_port, guest: 80, host: 8080

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  #config.vm.network :private_network, ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network :public_network

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  config.vm.provider :virtualbox do |vb|
     # Don't boot with headless mode
     vb.gui = false

     # Use VBoxManage to customize the VM. For example to change memory:
     vb.customize ["modifyvm", :id, "--memory", "1024"]
  end
  #
  # View the documentation for the provider you're using for more
  # information on available options.

  # Enable provisioning with Puppet stand alone.  Puppet manifests
  # are contained in a directory path relative to this Vagrantfile.
  # You will need to create the manifests directory and a manifest in
  # the file base.pp in the manifests_path directory.
  #

  config.vm.define :master do |master|
    master.vm.box = "centos65-x86_64-20131205"
    master.vm.network :private_network, ip: "192.168.50.10"
    master.vm.network :forwarded_port, guest: 3000, host: 3000
    master.vm.network :forwarded_port, guest: 8140, host: 8140
    #master.vm.synced_folder "hieradata", "/etc/puppet/hieradata"
    #master.vm.synced_folder "~/.ssh", "/root/.ssh"
    #master.vm.synced_folder "modules/modules", "/etc/puppet/modules"
    #master.vm.synced_folder "modules/manifests", "/etc/puppet/manifests"
    #master.vm.provision :shell, :path => "agent-setup.sh", :args => "master"
    master.vm.provision :shell, :path => "puppetbooty.sh", :args => "--type master --hostname master --proxy"
  end

  config.vm.define :centos do |centos|
    centos.vm.box = "centos65-x86_64-20131205"
    centos.vm.network :private_network, ip: "192.168.50.11"
    centos.vm.provision :shell, :path => "puppetbooty.sh", :args => "--type agent --master 192.168.50.10 --hostname centos --proxy"
  end
end