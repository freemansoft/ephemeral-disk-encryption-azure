#!/bin/bash

set -e

###NOTE: Adjust secret name and version in url as needed

export AZ_TOKEN=$(curl -fsSL -H 'Metadata: true' 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net' |jq -r '.access_token' )
exec curl -fsSL -H "Authorization: Bearer $AZ_TOKEN" -H "Content-Type: application/json" \
  'https://luks-test-kv.vault.azure.net/secrets/disk-encrypt-key/0ceb27b7d5b7489ba3b33721f1a20b3b?api-version=7.2' \
  | jq -r .value
