# CoreOS Packer for Vagrant Box

Build a Vagrant box with CoreOS

- Based on CoreOS 310.1.0
    - ***Still Fleet v0.2.0***
    - ***Still Docker v0.10.0***
- Add OEM files for Vagrant and patch them
    - Cf.) https://github.com/coreos/coreos-overlay/pull/568
    - Cf.) https://github.com/YungSang/coreos-packer/tree/overlay-568
- Enable the Docker daemon and open the port 4243

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

  config.vm.synced_folder ".", "/home/core/vagrant", id: "core", type: "nfs",  mount_options: ['nolock,vers=3,udp']

  config.vm.provision :docker do |d|
    d.pull_images "google/busybox"
    d.run "simple-echo",
      image: "google/busybox",
      args: "-p 8080:8080",
      cmd: "nc -p 8080 -l -l -e echo hello world!"
  end

  config.vm.network :forwarded_port, guest: 8080, host: 8080
end
```

```
$ vagrant up
$ docker version
$ docker images -t
$ docker ps -a
$ nc localhost 8080
hello world!
```

## License

[![CC0](http://i.creativecommons.org/p/zero/1.0/88x31.png)](http://creativecommons.org/publicdomain/zero/1.0/)  
To the extent possible under law, the person who associated CC0 with this work has waived all copyright and related or neighboring rights to this work.

- [CoreOS](https://coreos.com/) is under the [Apache 2.0 license](http://www.apache.org/licenses/LICENSE-2.0)?
