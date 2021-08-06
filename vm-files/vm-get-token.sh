#!/bin/bash
source env.sh

# curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash 

if ! command -v jq &> /dev/null
then
    sudo snap install jq
fi

echo "retrieving token for $identity_client_id"

token_response=$(curl "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&client_id=$identity_client_id&resource=https%3A%2F%2Fvault.azure.net" -H "Metadata:true" --silent )
#echo "oauth2 token response: $token_response"
# should examine response for .error and abort

assigned_identity_token=$(jq -r '.access_token' <<< "$token_response")
echo "retrieved oath2 identity token: $assigned_identity_token"
secret_response=$(curl $secret_id?api-version=7.2 -H "Authorization: Bearer $assigned_identity_token" -H "Content-Type: application/json" --silent )
#echo "retrieved secret response: $secret_response"
secret=$(jq -r '.value' <<< "$secret_response")
echo "retrieved secret: $secret"

