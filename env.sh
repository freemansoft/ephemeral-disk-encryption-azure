#!/bin/bash

# should set the subscription
region="EastUS"

# add version # to name  to avoid complications with soft-deleted keyvaults while testing
# keyvault deletes are soft deletes witha purgable recovery == 90 days 2021/07
root_name="luks-example-8"

resource_group="rg-$root_name"
key_vault_name="kv-$root_name"
key_name="kn-$root_name"
secret_name="sn-$root_name"


# user assigned managed identity instead of system assigned so we can 
identity_name="uai-$root_name"

# On Linux virtual machines, the temporary disk is typically /dev/sdb and is formatted and mounted to /mnt by the Azure Linux Agent
# Standard_A2_v2 20gb temp storage
# Standard_L8s_v2 machines have unmounted NvMe drive per 8 vcore and are expensive
vm_type="Standard_L8s_v2"
vm_name="vm-$root_name"
vm_admin_user="azureuser"

# commnent out login after logged in one time and prior to timeout
# TODO determine if login required
echo "running interactive login"
az login
