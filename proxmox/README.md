# Create custom Ubuntu cloud-init template for Proxmox

## Create Ubuntu VM

See [Ubuntu](ubuntu.md) 

## Create Debian VM

See [Debian](debian.md)

```sh
bash -c "$(wget -qLO - https://github.com/technoluc/technoluc/raw/main/proxmox/script-debian-vm.sh)"
```
## Test ubuntu/debian

```sh
bash -c "$(wget -qLO - https://raw.githubusercontent.com/technoluc/scripts/main/proxmox/test.sh)"
```


## Quick Create or Clone script

```sh
bash -c "$(wget -qLO - https://github.com/technoluc/technoluc/raw/main/proxmox/quick.sh)"
```
