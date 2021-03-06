#!/bin/bash
# This script's output is consumed by other scripts so all operations must be silent
# assumes snap is installed
# assumes this script and luks-env.sh created and installed in /etc

set -e
source /etc/luks-env.sh

export AZ_TOKEN=$(curl -fsSL -H "Metadata: true" "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&client_id=$identity_client_id&resource=https%3A%2F%2Fvault.azure.net" |jq -r '.access_token' )
exec curl -fsSL -H "Authorization: Bearer $AZ_TOKEN" -H "Content-Type: application/json" "$secret_id?api-version=7.2" | jq -r .value
