#!/bin/bash

DIR="$(cd "$(dirname "$0")" && pwd)"
source $DIR/env.sh

accounts=$(az account list)
if [ "[]" == "$accounts" ]; then 
    echo "running interactive login"
    az login
else
    echo "already logged in"
fi
