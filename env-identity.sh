#!/bin/bash
# The user identity was needed in more than one script

identity_metadata=$(az identity show --name $AZURE_IDENTITY_NAME --resource-group $AZURE_RESOURCE_GROUP)
# this should be the same as AZURE_IDENTITY_NAME
identity_name=$(jq -r ".name" <<< "$identity_metadata")
principal_id=$(jq -r ".principalId" <<< "$identity_metadata")
identity_id=$(jq -r ".id" <<< "$identity_metadata")
# client id is required for queries if multiple identities tied to VM
identity_client_id=$(        jq -r ".clientId"        <<< "$identity_metadata")
identity_client_secret_url=$(jq -r ".clientSecretUrl" <<< "$identity_metadata")
echo "UAI: $identity_name "
echo "UAI principal: $principal_id "
echo "UAI id: $identity_id "
echo "UAI client id: $identity_client_id"
echo "UAI client secret url: $identity_client_secret_url"
