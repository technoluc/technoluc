# Create custom Ubuntu cloud-init template for Proxmox

##  Download Ubuntu cloud-image
### Ubuntu 18.04
```
wget http://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img
```
### Ubuntu 20.04
```
wget http://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img
```
### Ubuntu 21.04
```
wget http://cloud-images.ubuntu.com/hirsute/current/hirsute-server-cloudimg-amd64.img
```
### Ubuntu 22.04
```
wget http://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
```

when bionic, hirsute or jammy images are used make sure to update below commands with the corresponding name

## Install Qemu Guest Agent in image (bionic|focal|hirsute|jammy)
```
virt-customize -a focal-server-cloudimg-amd64.img --install qemu-guest-agent
```

## Create Virtual Machine and import cloud-image 


```
qm create 9000 --name "focal-server-cloudinit-template" --memory 4096 --cores 4 --net0 virtio,bridge=vmbr0
```

```
qm importdisk 9000 focal-server-cloudimg-amd64.img --format qcow2 local-lvm
```

```
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
```

```
qm set 9000 --boot c --bootdisk scsi0
```

```
qm set 9000 --ide2 local-lvm:cloudinit
```

```
qm set 9000 --serial0 socket --vga serial0
```

```
qm set 9000 --agent enabled=1
```

```
qm template 9000
```

## Open Proxmox Web-UI
### Configure cloud-init
Open the cloud-init tab for the VM

Configure username, password and network (set to dhcp) and "Regenerate Image"


## (Full) Clone template  

### Set $NEW_VM_NAME (edit if you like but this VM will be turned into a template)

```
export NEW_VM_NAME=focal-server-cloudinit-template
```

```
qm clone 9000 9999 --full --name $NEW_VM_NAME
```

## Start VM

```
qm start 9999
```

## Configure template 
### Install packages and run commands in template
```
sudo apt install nfs-common python3-pip 
```
```
pip3 install thefuck
```
```
pip3 install tldr
```

### Prepare VM for template
```
sudo cloud-init clean
sudo rm /etc/machine-id
sudo rm /var/lib/dbus/machine-id
sudo truncate -s 0 /etc/machine-id
sudo ln -s /etc/machine-id /var/lib/dbus/machine-id
sudo shutdown
```

## Turn VM into template
### Run on Proxmox
```
qm template 9999
```

# Quick Clone template
### Set $NEW_VM_ID

```
export NEW_VM_ID=$(pvesh get /cluster/nextid)
```

### Set $NEW_VM_NAME (edit this, will also be hostname of new VM)

```
export NEW_VM_NAME=focal-server
```

## Clone VM

```
qm clone 9999 $NEW_VM_ID --full --name $NEW_VM_NAME
```

## Start VM

```
qm start $NEW_VM_ID
```