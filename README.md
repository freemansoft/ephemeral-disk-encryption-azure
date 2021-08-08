# Purpose
This project creates an Azure KeyVault Secret and then creates a VM and makes that secret visible to the VM.
* The entire process is scripted
* It creates a User Assigned identity and gives it access to the secret
* The VM must query for the secret with that identity

## WARNING
These scripts allocate LS_v2 machines by default because they have the local NVMe drives.  
LS_v2 machines are **expensive**. _tear down the VM_ when done using the provided scripts.
The Resource Group, KeyVault, Secrets and User Assigned Identity are cheap and don't cost much to retain.

You can create the Key Vault, Secrets and a VM using a cheaper VM without NVMe drives by changing the machine type in env.sh
This would be useful if you wanted to play with _Secrets_ and _Identities_ without the need of the NVMe drives.

Many different Azure VM types come with local storage.  That storage is automatically formatted and automounted.
They are not the VM types we are LUKS encrypting for document db usage.

## TODO
* All of this resource creation and customization **should** all be done with templates instead of scripts

## ISSUES
* The _Resource Group_ deletion script removes the KeyVault which have a default 90 day retention policy and cannot be re-created.

# Creating a Resource group, secretes and a VM
1. Install the Azure CLI.  
    * Ubuntu currently has the latest installed. So WSL2 developers running Ubuntu should be fine 
    * `az --version` should be 2.26.1 _or later_
1. Edit `env.sh` to set the resource names
1. Run scripts 0,1,2,3 to create resources.  The scripts are re-runable. 
    * `0-install-tools.sh` 
    * `1-login-az.sh`
    * `2-create-resources.sh`
    * `3-create-vm.sh` 
1. SSH onto the VM to verify
    * `ssh azureuser@<ip>` 
        * shown at the end of script `3-create-vm.sh`
    * Run `get-user-identity-secret.sh` 
        * Verify the User Assigned Identity has been applied to the server and the secret is retirevable.

Provisioning Script Functions
| Script | Function |
| ------ | -------- | 
| 0-install-tools.sh | Install the Azure CLI |
| 0-install-tools.sh | Install jq |
| 1-login-az.sh      | Get azure login credentials. Only runs login if not logged in |
| 2-create-resources.sh | Create Resource Group | 
| 2-create-resources.sh | Create Key Vault | 
| 2-create-resoruces.sh | Create Secret to be used as LUKS encryption key |
| 2-create-resources.sh | Create User Assigned Identity |
| 3-create-vm.sh        | Create a VM |
| 3-create-vm.sh        | Associate system identity and previously created User Assigned Identity to it | 
| 3-create-vm.sh        | Create customized scripts that install and  maintain LUKS encrypted drives |
| 3-create-vm.sh        | Copy scripts to VM using SCP |
| 3-create-vm.sh        | Provide user ssh connection string |


# Luks encrypting the local disk
The actual LUKS encryption is done by scritps installed onto the virtual machine.
The scripts in `vm-files` are installed on the Virtual Machine.
They setup and enable LUKS encryption across all NVMe drives.
* `lunks-key.sh` is the only real Azure dependency. It is responsible for retrieving the LUKS encryption key from the KeyVault.

## Enabling encryption on a provisioned VM
1. SSH into the vm per the output of `3.create-vm.sh`
    * `ssh azureuser@<ip>`
1. `cd vm-tools`
1. Partition the NVM. Add the mount to the /etc
    * Run `sudo bash command-line.sh`
1. run `df` and `lsblk` to verify the LUKS mount

# The file system after encryption
Standard_L16s_v2 with two ephemeral disks.
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
  └─data0   253:0    0  1.8T  0 crypt /data
nvme1n1     259:0    0  1.8T  0 disk
└─nvme1n1p1 259:1    0  1.8T  0 part
  └─data1   253:0    0  1.8T  0 crypt /data

```

# Destroying resources
Tear down the azure resources using these scripts. 
| Script | Function |
| ------ | -------- | 
| 8-destroy-vm.sh | to destroy the VM |
| 9-destroy-resource-group.sh | destroy the resource group. This will destroy the keyvault, the secret, the identity and the VM |

## References
* https://withblue.ink/2020/01/19/auto-mounting-encrypted-drives-with-a-remote-key-on-linux.html
* Files in vm-files sourced from https://gist.github.com/seanb4t/fc244805aec83e55bfd1d306c19cd624 
* https://www.azurecitadel.com/vm/identity/
* https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/tutorial-windows-vm-access-nonaad
* https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=apt
* https://docs.microsoft.com/en-us/azure/key-vault/general/manage-with-cli2
* Azure CLI Examples https://github.com/Azure-Samples/azure-cli-samples


