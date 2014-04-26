VM_NAME  := CoreOS Packer
BOX_NAME := CoreOS Box

PWD := `pwd`

box: coreos.box

disk: tmp/CoreOS.vmdk

coreos.box: tmp/CoreOS.vmdk box/override-plugin.rb box/vagrantfile.tpl
	vagrant halt -f
	#
	# Clone
	#
	-VBoxManage unregistervm "${BOX_NAME}" --delete
	VBoxManage clonevm "${VM_NAME}" --name "${BOX_NAME}" --register
	#
	# Clean up
	#
	VBoxManage storageattach "${BOX_NAME}" --storagectl "IDE Controller" --port 0 --device 0 --medium none
	VBoxManage storageattach "${BOX_NAME}" --storagectl "IDE Controller" --port 1 --device 0 --medium none
	VBoxManage storageattach "${BOX_NAME}" --storagectl "SATA Controller" --port 1 --device 0 --medium none
	VBoxManage storageattach "${BOX_NAME}" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "${HOME}/VirtualBox VMs/${BOX_NAME}/${BOX_NAME}-disk2.vmdk"
	VBoxManage closemedium disk "${HOME}/VirtualBox VMs/${BOX_NAME}/${BOX_NAME}-disk1.vmdk" --delete
	VBoxManage modifyvm "${BOX_NAME}" --ostype Linux26_64
	#
	# Package
	#
	rm -f coreos.box
	cd box; \
	vagrant package --base "${BOX_NAME}" --output ../coreos.box --include override-plugin.rb --vagrantfile vagrantfile.tpl

tmp/CoreOS.vmdk: tmp/coreos-install tmp/coreos-setup-environment oem/cloud-config.yml
	vagrant destroy -f
	VM_NAME="${VM_NAME}" vagrant up --no-provision
	vagrant provision
	vagrant suspend

parallels: coreos-parallels.box

coreos-parallels.box: tmp/CoreOS.vmdk parallels/metadata.json parallels/override-plugin.rb parallels/Vagrantfile
	vagrant halt -f
	#
	# Convert VMDK to HDD
	#
	rm -rf "${HOME}/Documents/Parallels/CoreOS.hdd"
	-prl_convert tmp/CoreOS.vmdk --allow-no-os
	#
	# Create Parallels VM
	#
	-prlctl unregister "${VM_NAME}"
	rm -rf "${HOME}/Documents/Parallels/${VM_NAME}.pvm"
	prlctl create "${VM_NAME}" --ostype linux --distribution linux-2.6 --no-hdd
	mv "${HOME}/Documents/Parallels/CoreOS.hdd" "${HOME}/Documents/Parallels/${VM_NAME}.pvm/"
	prlctl set "${VM_NAME}" --device-add hdd --image "${HOME}/Documents/Parallels/${VM_NAME}.pvm/CoreOS.hdd"
	prlctl set "${VM_NAME}" --device-bootorder "hdd0 cdrom0"
	#
	# Clone
	#
	-prlctl unregister "${BOX_NAME}"
	rm -rf "Parallels/${BOX_NAME}.pvm"
	prlctl clone "${VM_NAME}" --name "${BOX_NAME}" --template --dst "${PWD}/parallels"
	#
	# Clean up
	#
	rm -f "parallels/${BOX_NAME}.pvm/config.pvs.backup"
	rm -f "parallels/${BOX_NAME}.pvm/CoreOS.hdd/DiskDescriptor.xml.Backup"
	#
	# Package
	#
	rm -f coreos-parallels.box
	cd parallels; tar zcvf ../coreos-parallels.box *
	prlctl unregister "${BOX_NAME}"

parallels/metadata.json:
	mkdir -p parallels
	echo '{"provider": "parallels"}' > parallels/metadata.json

parallels/override-plugin.rb: box/override-plugin.rb
	mkdir -p parallels
	cp box/override-plugin.rb parallels/override-plugin.rb

parallels/Vagrantfile: box/vagrantfile.tpl
	mkdir -p parallels
	cp box/vagrantfile.tpl parallels/Vagrantfile

tmp/coreos-install:
	mkdir -p tmp
	curl -L https://raw.github.com/coreos/init/master/bin/coreos-install -o tmp/coreos-install
	chmod +x tmp/coreos-install

tmp/coreos-setup-environment:
	mkdir -p tmp
	curl -L https://raw.github.com/coreos/coreos-overlay/master/coreos-base/oem-vagrant/files/coreos-setup-environment -o tmp/coreos-setup-environment
	chmod +x tmp/coreos-setup-environment

test: coreos.box
	vagrant box remove coreos --provider virtualbox
	vagrant box add coreos coreos.box
	cd test; \
	BOX_NAME="coreos" vagrant destroy -f; \
	BOX_NAME="coreos" vagrant up; \
	echo "-----> docker version"; \
	docker version; \
	echo "-----> /etc/os-release"; \
	BOX_NAME="coreos" vagrant ssh -c "cat /etc/os-release"; \
	echo "-----> /etc/oem-release"; \
	BOX_NAME="coreos" vagrant ssh -c "cat /etc/oem-release"; \
	echo "-----> /etc/machine-id"; \
	BOX_NAME="coreos" vagrant ssh -c "cat /etc/machine-id"; \
	echo "-----> systemctl list-units"; \
	BOX_NAME="coreos" vagrant ssh -c "systemctl list-units --no-pager"; \
	BOX_NAME="coreos" vagrant suspend

ptest: coreos-parallels.box
	vagrant box remove coreos --provider parallels
	vagrant box add coreos coreos-parallels.box --provider parallels
	cd test; \
	BOX_NAME="coreos" vagrant destroy -f; \
	BOX_NAME="coreos" vagrant up --provider parallels; \
	echo "-----> docker version"; \
	BOX_NAME="coreos" vagrant ssh -c "docker version"; \
	echo "-----> /etc/os-release"; \
	BOX_NAME="coreos" vagrant ssh -c "cat /etc/os-release"; \
	echo "-----> /etc/oem-release"; \
	BOX_NAME="coreos" vagrant ssh -c "cat /etc/oem-release"; \
	echo "-----> /etc/machine-id"; \
	BOX_NAME="coreos" vagrant ssh -c "cat /etc/machine-id"; \
	echo "-----> systemctl list-units"; \
	BOX_NAME="coreos" vagrant ssh -c "systemctl list-units --no-pager"; \
	BOX_NAME="coreos" vagrant suspend

clean:
	vagrant destroy -f
	-VBoxManage unregistervm "${BOX_NAME}" --delete
	cd test; vagrant destroy -f
	rm -f coreos.box
	rm -rf tmp/
	rm -f coreos-parallels.box
	rm -rf parallels/

.PHONY: clean
