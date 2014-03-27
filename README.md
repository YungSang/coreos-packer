# CoreOS Packer for Vagrant Box

Build a Vagrant box with CoreOS

- Based on https://github.com/coreos/coreos-vagrant
- Add [override-plugin.rb](https://github.com/coreos/coreos-vagrant/blob/master/override-plugin.rb)
- Setup and enable Docker Daemon with `-H tcp://0.0.0.0:4243`
- Support Docker provisioner

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

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "yungsang/coreos"

  config.vm.network "forwarded_port", guest: 4243, host: 4243

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
