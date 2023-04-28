# Create custom Ubuntu cloud-init template for Proxmox

#  Download Ubuntu cloud-image

## Ubuntu Versions

18.04
```
version=bionic
```

20.04
```
version=focal
```

21.04
```
version=hirsute
```

22.04
```
version=jammy
```

### Download cloudimg
```
wget http://cloud-images.ubuntu.com/jammy/current/${version}-server-cloudimg-amd64.img
```


## Install Qemu Guest Agent in image (bionic|focal|hirsute|jammy)
```
virt-customize -a ${version}-server-cloudimg-amd64.img --install qemu-guest-agent
```

## Create Virtual Machine and import cloud-image 

```
vmid=8000
```

```
qm create ${vmid} --name "${version}-server-cloudinit-template" --memory 4096 --cores 4 --net0 virtio,bridge=vmbr0
```

```
qm importdisk ${vmid} ${version}-server-cloudimg-amd64.img --format qcow2 local-lvm
```

```
qm set ${vmid} --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-${vmid}-disk-0
```

```
qm set ${vmid} --boot c --bootdisk scsi0
```

```
qm set ${vmid} --ide2 local-lvm:cloudinit
```

```
qm set ${vmid} --serial0 socket --vga serial0
```

```
qm set ${vmid} --agent enabled=1
```

```
qm template ${vmid}
```

## Open Proxmox Web-UI
### Configure cloud-init
Open the cloud-init tab for the VM

Configure username, password and network (set to dhcp) and "Regenerate Image". Add SSH keys if you want but I'll be using password authentication


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

Enable PasswordAuthentication via SSH
```
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
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
