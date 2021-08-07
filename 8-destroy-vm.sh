#!/bin/bash
# Assumes
#   azure cli is installed
#   default subscription
# Destroys 
#   VM leaving all other resources unaffected

DIR="$(cd "$(dirname "$0")" && pwd)"
source $DIR/env.sh

# https://docs.microsoft.com/en-us/cli/azure/vm?view=azure-cli-latest#az_vm_delete
# should we add --force-deletion or --no-wait ?
echo "deleting $vm_name"
vm_delete_results=$( az vm delete \
    --resource-group "$resource_group" \
    --name "$vm_name" \
    --yes )

