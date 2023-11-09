#!/bin/bash

# Show options
echo "Choose an option:"
echo "1. Create a new virtual machine"
echo "2. Clone a virtual machine"
read -p "Option (1/2): " option

# Error handling
check_error() {
    if [ $? -ne 0 ]; then
        echo "An error occurred. The script is aborted."
        exit 1
    fi
}

if [ "$option" == "1" ]; then
    # Create a new virtual machine

    # Variable definitions
    CloudImgUrl="https://cdimage.debian.org/cdimage/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
    CloudImgFile="debian-12-genericcloud-amd64.qcow2"
    read -p "Virtual Machine Name? " vmname

    # VMID + 9000
    vmlist_file="/etc/pve/.vmlist"
    start_point=9000

    while grep -q "\"$start_point\":" "$vmlist_file"; do
        ((start_point++))
    done

    vmid=$start_point

    # Toon het resultaat
    echo "The next available VMID is: $vmid"

    # Download cloud image
    if [ ! -f "$CloudImgFile" ]; then
        # Download cloud image
        wget ${CloudImgUrl}
        check_error
    else
        echo "The file '$CloudImgFile' already exists. Skipping the download."
    fi

    # Install QEMU Guest Agent in the image
    virt-customize -a ${CloudImgFile} --install qemu-guest-agent
    check_error

    # Create a VM
    qm create ${vmid} --name ${vmname} --memory 4096 --cores 2 --net0 virtio,bridge=vmbr0
    check_error

    # Import the disk in qcow2 format (as an unused disk)
    qm importdisk ${vmid} ${CloudImgFile} local-lvm -format qcow2
    check_error

    # Attach the disk to the VM using VirtIO SCSI
    qm set ${vmid} --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-${vmid}-disk-0
    check_error

    # Cloud Init settings
    qm set ${vmid} --ide2 local:cloudinit --boot c --bootdisk scsi0 --serial0 socket --vga serial0
    check_error

    # Use a DHCP server on vmbr0 or use a static IP
    # qm set ${vmid} --ipconfig0 ip=10.10.10.222/24,gw=10.10.10.1
    qm set ${vmid} --ipconfig0 ip=dhcp
    check_error

    qm set ${vmid} --searchdomain tl --nameserver 10.0.1.111
    check_error

    # Enable QEMU Guest Agent
    qm set ${vmid} --agent enabled=1
    check_error

    # SSH keys (optional)
    read -p "SSH key file (leave blank for a password): " ssh_key_file
    if [ -n "$ssh_key_file" ]; then
        qm set ${vmid} --sshkey ${ssh_key_file}
    else
        read -p "Username? " username
        qm set ${vmid} --ciuser ${username}
        check_error
        read -s -p "Password: " password
        echo
        qm set ${vmid} --cipassword ${password}
        check_error
    fi

    # Ask if you want to start the VM
    read -p "Start the virtual machine? (y/n): " start_vm
    if [ "$start_vm" == "y" ]; then
        qm start ${vmid}
        read -p "Start Console? (y/n): " start_console
        if [ "$start_console" == "y" ]; then
            qm terminal ${vmid}
        fi
    fi

elif [ "$option" == "2" ]; then
    # Clone a virtual machine

    # Show a list of VMs and their IDs
    qm list | awk '{print $1, $2}' | column -t

    # Ask for VM ID
    read -p "Template VMID: " template_vmid
    # Ask for VM Name
    read -p "New VM name? " clone_name

    clone_vmid=$(pvesh get /cluster/nextid)

    qm clone ${template_vmid} ${clone_vmid} --full --name ${clone_name}
    check_error

    # The initial disk is only 2GB, so we make it larger
    qm resize ${clone_vmid} scsi0 +14G
    check_error

    # Get the total RAM in kB available on the host
    total_ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    total_ram_mb=$((total_ram_kb / 1024))
    total_ram_gb=$((total_ram_mb / 1024))

    # Get the available RAM in kB
    available_ram_kb=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    available_ram_mb=$((available_ram_kb / 1024))
    available_ram_gb=$((available_ram_mb / 1024))

    # Get the number of available CPU cores on the host
    available_cores=$(nproc)

    # Ask the user for the amount of RAM in GB
    read -p "Enter the amount of RAM in GB (Available: $available_ram_gb GB out of $total_ram_gb GB): " ram_gb

    # Check if the entered value is within the available RAM range
    if [ "$ram_gb" -le "$available_ram_gb" ]; then
        # Convert user input to MB
        ram_mb=$((ram_gb * 1024))

        # Ask the user for the number of CPU cores to allocate
        read -p "Enter the number of CPU cores to allocate (Available cores: $available_cores): " cores

        # Check if the entered number of cores is within the available range
        if [ "$cores" -le "$available_cores" ]; then
            # Now, you can use the 'ram_mb' and 'cores' variables in the 'qm set' command
            # Replace <VMID> with the actual VMID of the virtual machine.
            qm set ${clone_vmid} --memory $ram_mb --cores $cores
        else
            echo "Invalid number of CPU cores. Please select a value within the available range (1-$available_cores)."
        fi
    else
        echo "Invalid input. Please choose an amount of RAM within the available range (1-$available_ram_gb GB)."
        exit 1
    fi

    check_error

    # Ask if you want to start the new VM
    read -p "Start the new virtual machine? (y/n): " start_vm
    if [ "$start_vm" == "y" ]; then
        qm start ${clone_vmid}
        read -p "Start Console? (y/n): " start_console
        if [ "$start_console" == "y" ]; then
            qm terminal ${clone_vmid}
        fi
    fi

else
    echo "Invalid option. Choose 1 or 2."
fi
