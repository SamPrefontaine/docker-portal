# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.define name = "docker-portal" do |config|
    config.vm.hostname = "docker-portal"
    
    config.vm.box = "ubuntu"

    config.vm.network :forwarded_port, guest: 3000, host: 3000
    config.vm.network :forwarded_port, guest: 3001, host: 3001
    config.vm.network :forwarded_port, guest: 4243, host: 4243

    config.vm.network :private_network, ip: "192.168.200.5"
    #config.vm.network :public_network

    # If true, then any SSH connections made will enable agent forwarding.
    # Default value: false
    config.ssh.forward_agent = true

    config.vm.provision :shell, :inline=> "sudo apt-get -y install git"

    config.vm.provision :shell, :inline=> "wget http://nodejs.org/dist/v0.10.24/node-v0.10.24-linux-x64.tar.gz; tar zxvf node-v0.10.24-linux-x64.tar.gz; sudo mv node-v0.10.24-linux-x64 /opt/node"
    config.vm.provision :shell, :inline=> "sudo ln -s /opt/node/bin/node /usr/local/bin/node; sudo ln -s /opt/node/bin/npm /usr/local/bin/npm; sudo npm install -g coffee-script bower express"

    config.vm.provision :shell, :inline=> "sudo cp /vagrant/settings_default.coffee /vagrant/settings.coffee"
    config.vm.provision :shell, :inline=> "cp /vagrant/bowerrc /home/vagrant/.bowerrc"
    config.vm.provision :shell, :inline=> "sudo cp /vagrant/bowerrc /root/.bowerrc"
    config.vm.provision :shell, :inline=> "cd /vagrant; npm install; bower install --allow-root"

    config.vm.provision :shell, :inline=> "sudo mkdir /etc/docker.d; sudo mkdir /etc/docker.d/nodebuntu"
    config.vm.provision :shell, :inline=> "sudo cp /vagrant/nodebuntu-dockerfile /etc/docker.d/nodebuntu/Dockerfile"
    config.vm.provision :shell, :inline=> "sudo mkdir /etc/docker.d/docker-portal"
    config.vm.provision :shell, :inline=> "sudo cp /vagrant/docker-portal-dockerfile /etc/docker.d/docker-portal/Dockerfile"
    config.vm.provision :shell, :inline=> "sudo mkdir /etc/docker.d/docker-portal-test"
    config.vm.provision :shell, :inline=> "sudo cp /vagrant/docker-portal-test-dockerfile /etc/docker.d/docker-portal-test/Dockerfile"

    config.vm.provision :shell, :inline=> "sudo apt-get update; sudo apt-get -y upgrade"
    config.vm.provision :shell, :inline=> "sudo apt-get -y install language-pack-en linux-image-extra-`uname -r`"

    config.vm.provision :shell, :inline=> "sudo add-apt-repository -y ppa:saltstack/salt"
    config.vm.provision :shell, :inline=> "sudo wget -qO- https://get.docker.io/gpg | apt-key add -"
    config.vm.provision :shell, :inline=> "sudo echo deb http://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list"

    config.vm.provision :shell, :inline=> "sudo apt-get update"
    config.vm.provision :shell, :inline=> "sudo apt-get -y install salt-minion lxc-docker git python-pip supervisor"

    config.vm.provision :shell, :inline=> "sudo cp /vagrant/docker-portal-supervisor.conf /etc/supervisor/conf.d/;"

    config.vm.provision :shell, :inline=> "cd /etc/docker.d/nodebuntu; sudo docker build -t nodebuntu ."
    config.vm.provision :shell, :inline=> "cd /etc/docker.d/docker-portal; sudo docker build -t docker-portal ."
    config.vm.provision :shell, :inline=> "cd /etc/docker.d/docker-portal-test; sudo docker build -t docker-portal-test ."

    config.vm.provision :shell, :inline=> "sudo rm /etc/init/docker.conf; sudo cp /vagrant/docker.conf /etc/init/docker.conf; sudo service docker restart"

    config.vm.provision :shell, :inline=> "sudo docker run -d -name docker-portal-run-3001 -p 0.0.0.0:3001:3001 -e PORT=3001 -v /vagrant/:/opt/src -t docker-portal"
    config.vm.provision :shell, :inline=> "sudo docker run -d -name docker-portal-test-3009 -e PORT=3009 -v /vagrant/:/opt/src -t docker-portal-test"

    config.vm.provision :shell, :inline=> "sudo service supervisor stop; sudo service supervisor start"

    config.vm.provider :virtualbox do |vb|
      #   vb.gui = true
      vb.customize ["modifyvm", :id, "--memory", "1500"]
    end
  end
end
