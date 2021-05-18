# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure("2") do |config|

config.vm.define "pxeserver" do |server|
  config.vm.box = 'centos/7'
  server.vm.hostname = 'pxeserver'
  server.vm.network "private_network", ip: "10.0.0.20", virtualbox__intnet: 'pxenet'
  server.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
  end
  # ENABLE to setup PXE
  server.vm.provision "shell",
    name: "Setup PXE server",
    path: "setup_pxe.sh"
  end


# Cent OS 8.2
# config used from this
  config.vm.define "pxeclient" do |pxeclient|
    pxeclient.vm.box = 'centos/7'
    pxeclient.vm.hostname = 'pxeclient'
    #pxeclient.vm.network :private_network, ip: "10.0.0.21"
    pxeclient.vm.network "private_network", type: "dhcp", virtualbox__intnet: 'pxenet'
    pxeclient.vm.provider :virtualbox do |vb|
      vb.memory = "1024"
      vb.customize [
          'modifyvm', :id,
          '--nic1', 'nat',
          '--nic2', 'intnet',
          '--intnet2', 'pxenet',
          '--boot1', 'net'
        ]
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ['modifyvm', :id, '--nicbootprio2', '1']
    end
  end

end
