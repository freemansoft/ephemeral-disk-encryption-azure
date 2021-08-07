# Purpose
This project creates an Azure KeyVault Secret and then creates a VM and makes that secret visible to the VM.
* The entire process is scripted
* It creates a User Assigned identity and gives it access to the secret
* The VM must query for the secret with that identity

# WARNING
These scripts allocate LS_v2 machines by default.  They are **expensive** so _tear them down_ when done.

# TODO
* Add encryption of ephemeral disks using the secret retireved from Azure KeyValut

# Creating a Resource group, secretes and a VM
1. Install the Azure CLI.  
    * Ubuntu currently has the latest installed. So WSL2 developers running Ubuntu should be fine 
    * `az --version` should be 2.26.1 _or later_
1. Edit `env.sh` to set the resource names
1. Run scripts 0,1,2,3 to create resources.  The scripts are re-runable. 
    * `0...` install tooling.  It may _sudo_ to install snap or Azure CLI
    * `1...` log into Azure using the CLI
    * `2...` create the keyvault and a secret and an identity
    * `3...` create a VM. Associate the identity as user defined. Customize any utility vm files. Copy utility files to the VM via SSH
1. SSH onto the VM to verify
    * `ssh azureuser@<ip>` as shown at the end of script `3...sh`
    * Run `get-user-identity-secret.sh` to verify the identity has been applied to the server and the secret is retirevable.

# Luks encrypting the local disk
1. SSH into the vm per the output of `3...sh`
1. `cd vm-tools`
1. partition the NVMe, encrypt the partion. Add the mount to the /etc
    * Run `sudo bash command-line.sh`
1. run `df` and `lsblk` to verify the LUKS mount

# The file system after encryption
```
$ lsblk
NAME        MAJ:MIN RM  SIZE RO TYPE  MOUNTPOINT
loop0         7:0    0 99.4M  1 loop  /snap/core/11420
loop1         7:1    0  240K  1 loop  /snap/jq/6
sda           8:0    0   80G  0 disk
└─sda1        8:1    0   80G  0 part  /mnt
sdb           8:16   0   30G  0 disk
├─sdb1        8:17   0 29.9G  0 part  /
├─sdb14       8:30   0    4M  0 part
└─sdb15       8:31   0  106M  0 part  /boot/efi
sr0          11:0    1  628K  0 rom
nvme0n1     259:0    0  1.8T  0 disk
└─nvme0n1p1 259:1    0  1.8T  0 part
  └─data0   253:0    0  1.8T  0 crypt /data0
```

# Destroying resources
* Return to the host
* Run `8...` to destroy the VM
* Run `9...` destroy the resource group. This will destroy the keyvault, the secret, the identity and the VM

## References
* https://withblue.ink/2020/01/19/auto-mounting-encrypted-drives-with-a-remote-key-on-linux.html
* Files in vm-files sourced from https://gist.github.com/seanb4t/fc244805aec83e55bfd1d306c19cd624 
* https://www.azurecitadel.com/vm/identity/
* https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/tutorial-windows-vm-access-nonaad
* https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=apt


