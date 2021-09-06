#!/bin/bash
#
# Assumes 
#   azure cli is installed
#   jq is installed
#   default subscription
# Removes
#   Resource Group and all associates resources


# Edit env.sh to your preferences
source env.sh

az group delete --resource-group $AZURE_RESOURCE_GROUP