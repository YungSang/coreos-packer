coreos.box: template.json vagrantfile.tpl \
 	oem/cloud-config.yml oem/override-plugin.rb \
	tmp/box.ovf tmp/coreos_production_vagrant_image.vmdk tmp/insecure_private_key
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
	curl -L https://raw.github.com/mitchellh/vagrant/master/keys/vagrant -o tmp/insecure_private_key

clean:
	rm -f coreos.box
	rm -rf tmp/
	rm -rf output-*/

.PHONY: clean
