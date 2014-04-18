# CoreOS Packer for Vagrant Box

Build a Vagrant box with CoreOS

- Based on CoreOS 291.0.0
- Enable the Docker daemon
- Support Docker provisioner
- Add override-plugin.rb  
Cf.) https://github.com/coreos/coreos-vagrant/blob/master/override-plugin.rb
- *Use btrfs for Docker as well*  
"One unfortunate side effect of this change is that all Docker containers will need to be reinitialized on CoreOS (docker pull, or docker build). "  
Cf.) http://coreos.com/blog/new-filesystem-btrfs-cloud-config/  
- *Use docker-tcp.socket to expose the port 4243*  
Cf.) http://coreos.com/docs/launching-containers/building/customizing-docker/#enable-the-remote-api-on-a-new-socket
- *Override cloud-config.yml to setup Docker and /etc/oem-release*

## How to Build

```
$ make
```

## How to Use

```
$ vagrant box add coreos coreos.box
$ vagrant init coreos
$ vagrant up
```

Or

```
VAGRANTFILE_API_VERSION = "2"

Vagrant.require_version ">= 1.5.0"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "yungsang/coreos"

  config.vm.network "forwarded_port", guest: 4243, host: 4243

  config.vm.network "private_network", ip: "192.168.33.10"

  config.vm.provision :docker do |d|
    d.pull_images "busybox"
    d.run "busybox",
      cmd: "echo hello"
  end
end
```

```
$ vagrant up
$ docker version
$ docker images -t
$ docker ps -a
```

## License

[![CC0](http://i.creativecommons.org/p/zero/1.0/88x31.png)](http://creativecommons.org/publicdomain/zero/1.0/)  
To the extent possible under law, the person who associated CC0 with this work has waived all copyright and related or neighboring rights to this work.

- [CoreOS](https://coreos.com/) is under the [Apache 2.0 license](http://www.apache.org/licenses/LICENSE-2.0)?
