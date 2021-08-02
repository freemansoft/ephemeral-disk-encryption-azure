# Purpose
This project creates an Azure KeyVault Secret and then creates a VM and makes that secret visible to the VM.
* The entire process is scripted
* It creates a User Assigned identity and gives it access to the secret
* The VM must query for the secret with that identity

# WARNING
These scripts allocate LS_v2 machines by default.  They are **expensive** so _tear them down_ when done.

# TODO
* Add encryption of ephemeral disks using the secret retireved from Azure KeyValut

# Steps
1. Install the Azure CLI.  
    1. Ubuntu currently has the latest installed. So WSL2 developers running Ubuntu should be fine 
    1. `az --version` should be 2.26.1 _or later_
1. Run script `0` to create all the resources
    1. run the `ssh` command to connect to the vm
    1. run the `vm-tools.sh` script to retrieve the secret
1. Run script `9` to destroy all resources


## References
* https://withblue.ink/2020/01/19/auto-mounting-encrypted-drives-with-a-remote-key-on-linux.html
* https://gist.github.com/seanb4t/fc244805aec83e55bfd1d306c19cd624
* https://www.azurecitadel.com/vm/identity/
* https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/tutorial-windows-vm-access-nonaad
* https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=apt




## Creation messages to be investigated
```
WARNING: It is recommended to use parameter "--public-ip-sku Standard" to create new VM with Standard public IP. Please note that the default public IP used for VM creation will be changed from Basic to Standard in the future.

WARNING: No access was given yet to the 'vm-luks-example-3', because '--scope' was not provided. You should setup by creating a role assignment, e.g. 'az role assignment create --assignee <principal-id> --role contributor -g rg-luks-example-3' would let it access the current resource group. To get the pricipal id, run 'az vm show -g rg-luks-example-3 -n vm-luks-example-3 --query "identity.principalId" -otsv'
```
