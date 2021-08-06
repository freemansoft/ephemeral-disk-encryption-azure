#!/bin/bash
DIR="$(cd "$(dirname "$0")" && pwd)"
source $DIR/env.sh

if ! command -v jq &> /dev/null
then
    echo "installing jq with snap"
    sudo snap install jq
else
    echo "jq already installed"
fi

# assumes azure CLI installed
if ! command -v az &> /dev/null
then
    echo "installing Azure CLI"
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash 
else
    echo "Azure CLI already installed"
fi
