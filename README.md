# CoreOS Packer for Vagrant Box

Build a Vagrant box with CoreOS

- Based on https://github.com/coreos/coreos-vagrant

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