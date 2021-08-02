#!/bin/bash
#
# Assumes azure cli is installed
# Assumes jq is installed
# Assumes default subscription

# Edit env.sh to your preferences
source env.sh

echo "---------RESOURCE GROUP-------------------"
# TODO: add the region to this query!
rg_exists=$(az group exists --resource-group "$resource_group")
if [ "false" = "$rg_exists" ]; then 
    echo "creating resource group : $resource_group"
    # should we capture the output of this? would we lose error messages?
    az group create --name "$resource_group" -l "$region"
else
    echo "resource group exists: $resource_group"
fi
rg_metadata=$(az group list --query "[?name=='$resource_group']")
echo "using resource group: $rg_metadata"

echo "-------------KEYVAULT---------------"
# This keyvault is only for encryption - we will bind one role to it
all_vaults_metadata=$( az keyvault list --resource-group "$resource_group" --query "[?name=='$key_vault_name']")
if [ "[]" == "$all_vaults_metadata" ]; then 
    echo "creating key vault: $key_vault_name"
    keyvault_create_metadata=$(az keyvault create --name "$key_vault_name" --resource-group "$resource_group" --location "$region" )
else 
    echo "keyvault exists: $key_vault_name"
fi
keyvault_metadata=$(az keyvault show --resource-group "$resource_group" --name "$key_vault_name")
echo "keyvault_metadata: $keyvault_metadata"
keyvault_properties=$(jq '.properties' <<< "${keyvault_metadata}")
keyvault_uri=$( jq -r  '.vaultUri' <<< "${keyvault_properties}" ) 
echo "keyvault_uri: $keyvault_uri"

echo "----------SECRET------------------"
secret_metadata=$(az keyvault secret list --vault-name "$key_vault_name" --query "[?name=='$secret_name']")
#echo "secret metadata $secret_metadata"
if [ "[]" == "$secret_metadata" ]; then
    echo "creating_secret $secret_name"
    secret_value=$(dd bs=32 count=1 if=/dev/random | base64)
    secret_create_results=$(az keyvault secret set --name $secret_name --vault-name $key_vault_name --value $secret_value)
    echo "created secret: $secret_create_results"
else
    echo "secret exists $secret_name"
fi
secret_id=$(az keyvault secret show --vault-name "$key_vault_name" --name "$secret_name" --query id -o tsv )
echo "secret id: $secret_id"

echo "-----------USER ASSIGNED IDENTITY-----------------"
# user assigned identity
rg_identity_metadata=$(az identity list --resource-group "$resource_group")
echo "rg_identity_metadata: $rg_identity_metadata"
identity_metadata=$(jq -r --arg identity_name "$identity_name" '.[] | select(.name==$identity_name)' <<< "$rg_identity_metadata")
echo "identity_metadata: $identity_metadata"
if [ -z "$identity_metadata" ]; then
    echo "creating identity: $identity_name"
    identity_create_results=$(az identity create --resource-group "$resource_group" --name "$identity_name")
    echo "identity creation returned: $identity_create_results"
    identity_metadata=$identity_create_results
else 
    echo "identity exists: $identity_name"
fi
identity_name=$(jq -r ".name" <<< "$identity_metadata")
principal_id=$(jq -r ".principalId" <<< "$identity_metadata")
identity_id=$(jq -r ".id" <<< "$identity_metadata")
echo "User assigned identity: $identity_name principal: $principal_id id: $identity_id"
# client id is required for queries if multiple identities tied to VM
identity_client_id=$(        jq -r ".clientId"        <<< "$identity_metadata")
identity_client_secret_url=$(jq -r ".clientSecretUrl" <<< "$identity_metadata")
echo "user assigned identity client secret url: $identity_client_secret_url"

echo "adding policy and role assignment for $principal_id to $key_vault_name"
set_policy_results=$(az keyvault set-policy --secret-permissions get list --name $key_vault_name --object-id $principal_id)
set_role_assignment_results=$(az role assignment create --assignee $principal_id --role reader --resource-group $resource_group)

echo "------------VM----------------"
# Create the VM if it does not exist -- this is an example so we do it as simply as possible
# This command does not return the ip address
vms_metadata=$(az vm list --resource-group "$resource_group" --query "[?name=='$vm_name']")
if [ "[]" == "$vms_metadata" ]; then
    echo "creating vm $vm_name"
    # assign identity on creation
    vm_create_results=$( az vm create --resource-group "$resource_group" --name "$vm_name" \
        --assign-identity [system] $identity_id \
        --image UbuntuLTS --admin-username "$vm_admin_user" --generate-ssh-keys )
    public_ip=$(jq -r ".publicIpAddress" <<< "$vm_create_results")
    echo "Connect with: 'ssh $vm_admin_user@$public_ip'"
else
    echo "existing vm: $vms_metadata"
    public_ip=$(az vm show -d --resource-group "$resource_group" --name "$vm_name" --query publicIps -o tsv)
    echo "vm exists -- assuming admin id is same and ssh keys exist ==> 'ssh $vm_admin_user@$public_ip' "
fi
# 

# verification hints
# ssh into the remote hosts
# retrieve the secret using the scripts 'on the remote'
# we want to somehow copy the code or just the values below to the newly created remote machine
# or we want to amke it where the system account can look up the client id and the secret id
echo ""
echo "==============================="
echo "----------connect       ------------------"
echo "ssh $vm_admin_user@$public_ip"
echo "----------one the remote------------------"
echo "sudo snap install jq"
echo ""
echo "assigned_identity_token=\$(curl 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&client_id=$identity_client_id&resource=https%3A%2F%2Fvault.azure.net' -H Metadata:true | jq -r '.access_token')"
echo 'curl' $secret_id'?api-version=7.2 -H "Authorization: Bearer $assigned_identity_token" -H "Content-Type: application/json"'
echo "==============================="
# add additional code to pull down the LUKS encryption files




