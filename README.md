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
1. Run scripts 0,1,2,3 to create resources.  The scripts are re-runable
    * `0...` install tooling
    * `1...` log into Azure using the CLI
    * `2...` create the keyvault and a secret and an identity
    * `3...` create a VM. Associate the identity as user defined. Customize any utility vm files. Copy utility files to the VM via SSH
1. SSH onto the VM to verify
    * Run `get-user-identity-secret.sh` to verify the identity has been applied to the server and the secret is retirevable.

# Luks encrypting the local disk
1. SSH into the vm
1. Run `sudo command-line.sh`
1. run `df` to verify the LUKS mount

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


