#!/bin/bash

# should set the subscription
AZURE_REGION="EastUS"

# add version # to name  to avoid complications with soft-deleted keyvaults while testing
# keyvault deletes are soft deletes witha purgable recovery == 90 days 2021/07
root_name="luks-example-12"

AZURE_RESOURCE_GROUP="rg-$root_name"
AZURE_KEY_VAULT_NAME="kv-$root_name"
key_name="kn-$root_name"
secret_name="sn-$root_name"


# user assigned managed identity instead of system assigned so we can 
AZURE_IDENTITY_NAME="uai-$root_name"
# On Azure Linux Virtual Machines, the temporary disk is typically /dev/sdb and is formatted and mounted to /mnt by the Azure Linux Agent
# Standard_A2_v2 20gb temp storage with no NVMe
# On storage optimized machine there are NVMe drives that are not mounted /dev/nvme[0..n]n1
# Standard_L8s_v2 machines have one unmounted NvMe drive per 8 vcore and are expensive. 
# Standard_L16s_v2 are double everything
AZURE_VM_TYPE="Standard_A2_v2"
#AZURE_VM_TYPE="Standard_L8s_v2"
AZURE_VM_TYPE="Standard_L16s_v2"

vm_name="vm-$root_name"
vm_admin_user="azureuser"

