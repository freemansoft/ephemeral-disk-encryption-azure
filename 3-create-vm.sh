#!/bin/bash
# Assumes 
#   azure cli is installed
#   jq is installed
#   default subscription
# Provisions
#   Create a VM
#   Assigns User Assigned Identity
#   Create the env.sh file 
#   Push the client files to the VM

DIR="$(cd "$(dirname "$0")" && pwd)"
source $DIR/env.sh

# we need to asssociate the identity that has access to the secret
source $DIR/env-identity.sh
#az vm list-sizes --location $AZURE_REGION --output table
# Create the VM if it does not exist -- this is an example so we do it as simply as possible
# This command does not return the ip address
vms_metadata=$(az vm list --resource-group "$AZURE_RESOURCE_GROUP" --query "[?name=='$vm_name']")
if [ "[]" == "$vms_metadata" ]; then
    echo "creating vm $vm_name"

    # assign identity on creation
    vm_create_results=$( az vm create --resource-group "$AZURE_RESOURCE_GROUP" \
        --name "$vm_name" \
        --assign-identity [system] $identity_id \
        --image UbuntuLTS \
        --admin-username "$vm_admin_user" \
        --size "$AZURE_VM_TYPE" \
        --public-ip-sku Standard \
        --generate-ssh-keys )
    public_ip=$(jq -r ".publicIpAddress" <<< "$vm_create_results")
    echo "Connect with: 'ssh $vm_admin_user@$public_ip'"
else
    echo "existing vm: $vms_metadata"
    public_ip=$(az vm show -d --resource-group "$AZURE_RESOURCE_GROUP" --name "$vm_name" --query publicIps -o tsv)
    echo "vm exists -- assuming admin id is same and ssh keys exist ==> 'ssh $vm_admin_user@$public_ip' "
fi

echo "----------REMOTE ENV------------------"
echo "creating vm-files/luks-env.sh"
secret_id=$(az keyvault secret show --vault-name "$AZURE_KEY_VAULT_NAME" --name "$secret_name" --query id -o tsv )
cat > vm-files/luks-env.sh <<EOL
#!/bin/bash
# created `date` specifically for User Defined Identity and Secret
identity_client_id="$identity_client_id"
secret_id="$secret_id"
EOL

# assumes vm-env.sh created in previous step
echo "copying files to VM"
scp -rpq $DIR/vm-files $vm_admin_user@$public_ip:.

echo "----------connect------------------"
echo "ssh $vm_admin_user@$public_ip"
