#!/bin/bash

# should set the subscription
region="EastUS"

# this exist here because if your are testing to avoid complications with soft-deleted resources while testing
# keyvault deletes are soft deletes witha purgable recovery == 90 days 2021/07
root_name="luks-example-5"
resource_group="rg-$root_name"
key_vault_name="kv-$root_name"
key_name="kn-$root_name"
secret_name="sn-$root_name"

# user assigned managed identity instead of system assigned so we can 
identity_name="uai-$root_name"

vm_name="vm-$root_name"
vm_admin_user="azureuser"

# commnent out login after logged in one time and prior to timeout
# TODO determine if login required
echo "running interactive login"
az login
