# Create custom Ubuntu cloud-init template for Proxmox

## Debian Versions

12 (BookWorm)

```sh
CloudImgUrl=https://cdimage.debian.org/cdimage/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2
CloudImgFile=debian-12-genericcloud-amd64.qcow2
```

## Create Virtual Machine and import cloud-image

```sh
# Download cloud img 
wget ${CloudImgUrl}

# Install Qemu Guest Agent in image
virt-customize -a ${CloudImgFile} --install qemu-guest-agent
vmname=tacticalrmm
CloudImgFile=debian-12-genericcloud-amd64.qcow2
vmid=9110

# Create a VM
qm create ${vmid} --name ${vmname} --memory 4096 --cores 2 --net0 virtio,bridge=vmbr0

# Import the disk in qcow2 format (as unused disk) 
qm importdisk ${vmid} ${CloudImgFile} local-lvm -format qcow2

# Attach the disk to the vm using VirtIO SCSI
qm set ${vmid} --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-${vmid}-disk-0

# Important settings
qm set ${vmid} --ide2 local:cloudinit --boot c --bootdisk scsi0 --serial0 socket --vga serial0

# The initial disk is only 2GB, thus we make it larger
qm resize ${vmid} scsi0 +30G

# Using a  dhcp server on vmbr1 or use static IP
qm set ${vmid} --ipconfig0 ip=dhcp
#qm set ${vmid} --ipconfig0 ip=10.10.10.222/24,gw=10.10.10.1

# Enable Qemu Guest Agent
qm set ${vmid} --agent enabled=1
```

## Setup SSH access

```sh
# SSH-sleutels (optioneel)
read -p "SSH-sleutelbestand (leeglaten voor wachtwoord): " ssh_key_file
if [ -n "$ssh_key_file" ]; then
    qm set ${vmid} --sshkey ${ssh_key_file}
else
    read -p "AweSomeUserName? " AweSomeUserName
    echo
    qm set ${vmid} --ciuser ${AweSomeUserName}
    read -s -p "AweSomePassword: " AweSomePassword
    echo
    qm set ${vmid} --cipassword ${AweSomePassword}
fi
```

> ### Alternative SSH and DHCP settings in Proxmox GIU
> 
> Open the cloud-init tab for the VM
>
> Configure username, password and network (set to dhcp) and "Regenerate Image". Add SSH keys if you want but I'll be using password authentication

Now start the machine or configure for template.

## Configure template  

### Set $TemplateName and clone

```sh
export TemplateName=debian-12-cloudinit-template
```

### Start VM

```sh
qm start ${vmid}
```

### Configure template

#### Install packages and run commands in template, for example;

```sh
# Install packages for NFS and python
sudo apt install nfs-common python3-pip 
# Enable PasswordAuthentication via SSH
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
```

#### Prepare VM for template

```sh
sudo cloud-init clean
sudo rm /etc/machine-id
sudo rm /var/lib/dbus/machine-id
sudo truncate -s 0 /etc/machine-id
sudo ln -s /etc/machine-id /var/lib/dbus/machine-id
sudo shutdown now
```

## Turn VM into template

```sh
qm template ${vmid}
```

# Quick Clone template

### Set $NEW_VM_ID

```sh
export NEW_VM_ID=$(pvesh get /cluster/nextid)

```

### Set $TemplateName (edit this, will also be hostname of new VM)

```sh
read -p "New VM-name? " TemplateName
```

### Clone VM

```sh
qm clone 9110 $NEW_VM_ID --full --name $TemplateName
```

### Start VM

```sh
qm start $NEW_VM_ID
```


