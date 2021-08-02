#!/bin/bash
#
# Assumes azure cli is installed
# Assumes jq is installed
# Assumes default subscription

# Edit env.sh to your preferences
source env.sh

az group delete --resource-group $resource_group