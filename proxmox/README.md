# Create custom cloud-init template for Proxmox

Run the following in PVE shell to create a Debian 12 VM

```sh
bash -c "$(wget -qLO - https://github.com/technoluc/technoluc/raw/main/proxmox/script-debian-vm.sh)"
```

## Create Ubuntu VM

See [Ubuntu](ubuntu.md) 

## Create Debian VM

See [Debian](debian.md)

## Quick Create or Clone script

```sh
bash -c "$(wget -qLO - https://github.com/technoluc/technoluc/raw/main/proxmox/quick.sh)"
```

## Test ubuntu/debian W.I.P.

```sh
bash -c "$(wget -qLO - https://raw.githubusercontent.com/technoluc/scripts/main/proxmox/test.sh)"
```
