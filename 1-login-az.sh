#!/bin/bash
# https://docs.microsoft.com/en-us/cli/azure/authenticate-azure-cli

DIR="$(cd "$(dirname "$0")" && pwd)"
source $DIR/env.sh

# this command fails if not logged in or have expired token
if !  az account list-locations > /dev/null ; then
    echo "running interactive login"
    az login
else
    echo "already logged in"
fi
