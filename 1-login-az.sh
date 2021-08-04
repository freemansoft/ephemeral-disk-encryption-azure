#!/bin/bash

source env.sh

accounts=$(az account list)
if [ "[]" == "$accounts" ]; then 
    echo "running interactive login"
    az login
else
    echo "already logged in"
fi
