#!/bin/bash

identity_metadata=$(az identity show --name $identity_name --resource-group $resource_group)

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
