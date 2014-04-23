VM_NAME  := CoreOS Packer
BOX_NAME := CoreOS Box

box: coreos.box

disk: tmp/CoreOS.vmdk

coreos.box: tmp/CoreOS.vmdk
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

tmp/CoreOS.vmdk: tmp/coreos-install oem/cloud-config.yml box/override-plugin.rb box/vagrantfile.tpl
	vagrant destroy -f
	VM_NAME="${VM_NAME}" vagrant up --no-provision
	vagrant provision
	vagrant suspend

tmp/coreos-install:
	mkdir -p tmp
	curl -L https://raw.github.com/coreos/init/master/bin/coreos-install -o tmp/coreos-install
	chmod +x tmp/coreos-install

test: coreos.box
	vagrant box remove coreos
	vagrant box add coreos coreos.box
	cd test; \
	vagrant destroy -f; \
	vagrant up; \
	echo "-----> docker version"; \
	docker version; \
	echo "-----> /etc/os-release"; \
	vagrant ssh -c "cat /etc/os-release"; \
	echo "-----> /etc/oem-release"; \
	vagrant ssh -c "cat /etc/oem-release"; \
	echo "-----> /etc/machine-id"; \
	vagrant ssh -c "cat /etc/machine-id"; \
	echo "-----> systemctl list-units"; \
	vagrant ssh -c "systemctl list-units --no-pager"; \
	vagrant suspend

clean:
	vagrant destroy -f
	-VBoxManage unregistervm "${BOX_NAME}" --delete
	cd test; vagrant destroy -f
	rm -f coreos.box
	rm -rf tmp/

.PHONY: clean
