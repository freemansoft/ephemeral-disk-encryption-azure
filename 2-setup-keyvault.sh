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
rg_identity_metadata=$(az identity list --resource-group "$resource_group"  --query "[?name=='$identity_name']")
echo "rg_identity_metadata: $rg_identity_metadata"
if [ "[]" == "$rg_identity_metadata" ]; then
    echo "creating identity: $identity_name"
    identity_create_results=$(az identity create --resource-group "$resource_group" --name "$identity_name")
    echo "identity creation returned: $identity_create_results"
else 
    echo "identity exists: $identity_name"
fi
# retrieve the identity info
source env-identity.sh

echo "adding policy and role assignment for $principal_id to $key_vault_name"
set_policy_results=$(az keyvault set-policy --secret-permissions get list --name $key_vault_name --object-id $principal_id)
#set_role_assignment_results=$(az role assignment create --assignee $principal_id --role reader --resource-group $resource_group)


echo "----------REMOTE ENV------------------"
echo "creating vm-files/env.sh"
cat > vm-files/env.sh <<EOL
#!/bin/bash
# created `date`
# 

identity_client_id=$identity_client_id
secret_id=$secret_id

EOL



