# Create custom Ubuntu cloud-init template for Proxmox

## Ubuntu Versions

### 18.04 (Bionic)
```sh
CloudImgUrl=http://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img
```

### 20.04 (Focal)
```sh
CloudImgUrl=http://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img
```

### 21.04 (Hirsute)
```sh
CloudImgUrl=http://cloud-images.ubuntu.com/hirsute/current/hirsute-server-cloudimg-amd64.img
```

### 22.04 (Jammy)
```sh
CloudImgUrl=http://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
```

## Create Virtual Machine and import cloud-image

```sh
vmid=8000
CloudImgFile=$(basename $CloudImgUrl)
TemplateName=$(basename $CloudImgUrl | cut -d'-' -f1,2)

# Download cloud img 
wget -q --show-progress ${CloudImgUrl}
echo -en "\e[1A\e[0K"
echo "Downloaded ${CloudImgFile}"

# Install Qemu Guest Agent in image
virt-customize -a ${CloudImgFile} --install qemu-guest-agent

# Create a VM
qm create ${vmid} --name ${TemplateName} --memory 4096 --cores 4 --net0 virtio,bridge=vmbr0

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

## Configure for template  

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

Do whatever you like, the next step is to shutdown and prepare the VM. 

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
# Set $NEW_VM_ID
export NEW_VM_ID=$(pvesh get /cluster/nextid)
# Set $CloneName (edit this, will also be hostname of new VM)
read -p "New VM-name? " CloneName
# Clone VM
qm clone ${vmid} $NEW_VM_ID --full --name $CloneName
# Start VM
qm start $NEW_VM_ID
```
