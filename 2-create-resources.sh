#!/bin/bash
#
# Assumes 
#   azure cli is installed
#   jq is installed
#   default subscription
# Provisions
#   Resource Group
#   Key Vault
#   Secret
#   User Assigned Identity

# Edit env.sh to your preferences
DIR="$(cd "$(dirname "$0")" && pwd)"
source $DIR/env.sh

echo "---------RESOURCE GROUP-------------------"
# TODO: add the region to this query!
rg_exists=$(az group exists --resource-group "$AZURE_RESOURCE_GROUP")
if [ "false" = "$rg_exists" ]; then 
    echo "creating resource group : $AZURE_RESOURCE_GROUP"
    # should we capture the output of this? would we lose error messages?
    az group create --name "$AZURE_RESOURCE_GROUP" -l "$AZURE_REGION"
else
    echo "resource group exists: $AZURE_RESOURCE_GROUP"
fi
rg_metadata=$(az group list --query "[?name=='$AZURE_RESOURCE_GROUP']")
echo "using resource group: $rg_metadata"

echo "-------------KEYVAULT---------------"
# This keyvault is only for encryption - we will bind one role to it
all_vaults_metadata=$( az keyvault list --resource-group "$AZURE_RESOURCE_GROUP" --query "[?name=='$AZURE_KEY_VAULT_NAME']")
if [ "[]" == "$all_vaults_metadata" ]; then 
    echo "creating key vault: $AZURE_KEY_VAULT_NAME"
    keyvault_create_metadata=$(az keyvault create --name "$AZURE_KEY_VAULT_NAME" --resource-group "$AZURE_RESOURCE_GROUP" --location "$AZURE_REGION" )
else 
    echo "keyvault exists: $AZURE_KEY_VAULT_NAME"
fi
keyvault_metadata=$(az keyvault show --resource-group "$AZURE_RESOURCE_GROUP" --name "$AZURE_KEY_VAULT_NAME")
echo "keyvault_metadata: $keyvault_metadata"
keyvault_properties=$(jq '.properties' <<< "${keyvault_metadata}")
keyvault_uri=$( jq -r  '.vaultUri' <<< "${keyvault_properties}" ) 
echo "keyvault_uri: $keyvault_uri"

echo "----------SECRET------------------"
secret_metadata=$(az keyvault secret list --vault-name "$AZURE_KEY_VAULT_NAME" --query "[?name=='$secret_name']")
#echo "secret metadata $secret_metadata"
if [ "[]" == "$secret_metadata" ]; then
    echo "creating_secret $secret_name"
    secret_value=$(dd bs=32 count=1 if=/dev/random | base64)
    secret_create_results=$(az keyvault secret set --name $secret_name --vault-name $AZURE_KEY_VAULT_NAME --value $secret_value)
    echo "created secret: $secret_create_results"
else
    echo "secret exists $secret_name"
fi
secret_id=$(az keyvault secret show --vault-name "$AZURE_KEY_VAULT_NAME" --name "$secret_name" --query id -o tsv )
echo "secret id: $secret_id"

echo "-----------USER ASSIGNED IDENTITY-----------------"
# user assigned identity
rg_identity_metadata=$(az identity list --resource-group "$AZURE_RESOURCE_GROUP"  --query "[?name=='$AZURE_IDENTITY_NAME']")
echo "rg_identity_metadata: $rg_identity_metadata"
if [ "[]" == "$rg_identity_metadata" ]; then
    echo "creating identity: $AZURE_IDENTITY_NAME"
    identity_create_results=$(az identity create --resource-group "$AZURE_RESOURCE_GROUP" --name "$AZURE_IDENTITY_NAME")
    echo "identity creation returned: $identity_create_results"
else 
    echo "identity exists: $AZURE_IDENTITY_NAME"
fi
# retrieve the identity info
source env-identity.sh

echo "adding policy and role assignment for $principal_id to $AZURE_KEY_VAULT_NAME"
set_policy_results=$(az keyvault set-policy --secret-permissions get list --name $AZURE_KEY_VAULT_NAME --object-id $principal_id)
#set_role_assignment_results=$(az role assignment create --assignee $principal_id --role reader --resource-group $AZURE_RESOURCE_GROUP)


echo "----------REMOTE ENV------------------"
echo "creating vm-files/env.sh"
cat > vm-files/env.sh <<EOL
#!/bin/bash
# created `date`
# 

identity_client_id=$identity_client_id
secret_id=$secret_id

EOL



