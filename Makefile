boot2coreos.box: template.json vagrantfile.tpl files/docker-tcp.socket \
	tmp/box.ovf tmp/coreos_production_vagrant_image.vmdk tmp/insecure_private_key \
	tmp/override-plugin.rb
	packer build template.json

tmp/box.ovf: tmp/coreos_production_vagrant.box
	cd tmp; \
	tar zxvfm coreos_production_vagrant.box box.ovf

tmp/coreos_production_vagrant_image.vmdk: tmp/coreos_production_vagrant.box
	cd tmp; \
	tar zxvfm coreos_production_vagrant.box coreos_production_vagrant_image.vmdk

tmp/coreos_production_vagrant.box:
	mkdir -p tmp
	cd tmp; \
	curl -LO http://storage.core-os.net/coreos/amd64-usr/alpha/coreos_production_vagrant.box

tmp/insecure_private_key:
	mkdir -p tmp
	cd tmp; \
	curl -L https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant -o insecure_private_key

tmp/override-plugin.rb:
	mkdir -p tmp
	cd tmp; \
	curl -LO https://raw.githubusercontent.com/coreos/coreos-vagrant/master/override-plugin.rb

clean:
	rm -r coreos.box
	rm -rf tmp/
	rm -rf output-*/

.PHONY: clean
