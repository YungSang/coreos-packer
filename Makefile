VM_NAME  := CoreOS Packer
BOX_NAME := CoreOS Box

VERSION_ID := 0.9.8
BUILD_ID   := `date -u '+%Y-%m-%d-%H%M'`
CHANNEL    := beta

PWD := `pwd`

box: coreos.box

disk: tmp/CoreOS.vmdk

coreos.box: tmp/CoreOS.vmdk box/change_host_name.rb box/configure_networks.rb box/vagrantfile.tpl
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
	vagrant package --base "${BOX_NAME}" --output ../coreos.box --include change_host_name.rb,configure_networks.rb --vagrantfile vagrantfile.tpl

tmp/CoreOS.vmdk: Vagrantfile oem/coreos-setup-environment tmp/coreos-install tmp/cloud-config.yml
	vagrant destroy -f
	VM_NAME="${VM_NAME}" vagrant up --no-provision
	CHANNEL="${CHANNEL}" vagrant provision
	vagrant suspend

parallels: coreos-parallels.box

coreos-parallels.box: tmp/CoreOS.vmdk parallels/metadata.json parallels/change_host_name.rb parallels/configure_networks.rb parallels/Vagrantfile
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

parallels/change_host_name.rb: box/change_host_name.rb
	mkdir -p parallels
	cp box/change_host_name.rb parallels/change_host_name.rb

parallels/configure_networks.rb: box/configure_networks.rb
	mkdir -p parallels
	cp box/configure_networks.rb parallels/configure_networks.rb

parallels/Vagrantfile: box/vagrantfile.tpl
	mkdir -p parallels
	cp box/vagrantfile.tpl parallels/Vagrantfile

tmp/coreos-install:
	mkdir -p tmp
ifneq ($(CHANNEL),master)
	curl -L https://raw.github.com/coreos/init/master/bin/coreos-install -o tmp/coreos-install
	chmod +x tmp/coreos-install
else
	cp oem/coreos-install tmp/coreos-install
endif

tmp/cloud-config.yml: oem/cloud-config.yml
	mkdir -p tmp
	sed -e "s/%VERSION_ID%/${VERSION_ID}/g" -e "s/%BUILD_ID%/${BUILD_ID}/g" oem/cloud-config.yml > tmp/cloud-config.yml

test: test/Vagrantfile coreos.box
	@vagrant box add -f coreos coreos.box
	@cd test; \
	vagrant destroy -f; \
	vagrant up; \
	echo "-----> docker version"; \
	DOCKER_HOST="tcp://localhost:2375"; \
	docker version; \
	echo "-----> docker images -t"; \
	docker images -t; \
	echo "-----> docker ps -a"; \
	docker ps -a; \
	echo "-----> nc localhost 8080"; \
	nc localhost 8080; \
	echo "-----> /etc/os-release"; \
	vagrant ssh -c "cat /etc/os-release"; \
	echo "-----> /etc/oem-release"; \
	vagrant ssh -c "cat /etc/oem-release"; \
	echo "-----> /etc/machine-id"; \
	vagrant ssh -c "cat /etc/machine-id"; \
	echo "-----> /etc/hostname"; \
	vagrant ssh -c "cat /etc/hostname"; \
	echo "-----> /etc/environment"; \
	vagrant ssh -c "cat /etc/environment"; \
	echo "-----> /etc/systemd/network/50-vagrant*.network"; \
	vagrant ssh -c "cat /etc/systemd/network/50-vagrant*.network"; \
	echo "-----> route"; \
	vagrant ssh -c "route"; \
	echo "-----> systemctl list-units"; \
	vagrant ssh -c "systemctl list-units --no-pager"; \
	vagrant suspend

ptest: DOCKER_HOST_IP=$(shell cd test; vagrant ssh-config | sed -n "s/[ ]*HostName[ ]*//gp")
ptest: ptestup
	@cd test; \
	echo "-----> docker version"; \
	DOCKER_HOST="tcp://${DOCKER_HOST_IP}:2375"; \
	docker version; \
	echo "-----> docker images -t"; \
	docker images -t; \
	echo "-----> docker ps -a"; \
	docker ps -a; \
	echo "-----> nc ${DOCKER_HOST_IP} 8080"; \
	nc ${DOCKER_HOST_IP} 8080; \
	echo "-----> /etc/os-release"; \
	vagrant ssh -c "cat /etc/os-release"; \
	echo "-----> /etc/oem-release"; \
	vagrant ssh -c "cat /etc/oem-release"; \
	echo "-----> /etc/machine-id"; \
	vagrant ssh -c "cat /etc/machine-id"; \
	echo "-----> /etc/hostname"; \
	vagrant ssh -c "cat /etc/hostname"; \
	echo "-----> /etc/environment"; \
	vagrant ssh -c "cat /etc/environment"; \
	echo "-----> /etc/systemd/network/50-vagrant*.network"; \
	vagrant ssh -c "cat /etc/systemd/network/50-vagrant*.network"; \
	echo "-----> route"; \
	vagrant ssh -c "route"; \
	echo "-----> systemctl list-units"; \
	vagrant ssh -c "systemctl list-units --no-pager"; \
	vagrant suspend

ptestup: test/Vagrantfile coreos-parallels.box
	@vagrant box add -f coreos coreos-parallels.box --provider parallels
	@cd test; \
	vagrant destroy -f; \
	vagrant up --provider parallels; \

clean:
	vagrant destroy -f
	-VBoxManage unregistervm "${BOX_NAME}" --delete
	cd test; vagrant destroy -f
	rm -f coreos.box
	rm -rf tmp/
	rm -f coreos-parallels.box
	rm -rf parallels/

.PHONY: box test clean
