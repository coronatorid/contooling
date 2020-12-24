#!/bin/bash

# Variable
# SERVICE = deployed services
# RELEASE_TAG = deployment tag of a services
# SSH_PRIVATE_KEY
# SSH_PUBLIC_KEY
# SERVER_USER
# SERVER_HOST


echo "START DEPLOYMENT PROCESS"

if [ -z $SERVICE ] || [ -z $RELEASE_TAG ] || [ -z $SSH_PRIVATE_KEY ] || [ -z $SSH_PUBLIC_KEY ] || [ -z $SERVER_USER ] || [ -z $SERVER_HOST ]; then
    echo "Some variable is not initiated, exiting deployment process."
    exit 1
fi

if [ -d "./$SERVICE" ]; then
    echo "Deploying $SERVICE. Release: $RELEASE_TAG"
    echo "Change directory to respective services"
    
    cd ./$SERVICE
    
    echo "Showing all files in directory"
    echo "========================================"
    ls -la
    echo "========================================"
    
    echo "TAG=$RELEASE_TAG" >> .env
    
    echo "========================================"
    echo "SSH Preparation"
    
    echo "$SSH_PRIVATE_KEY" >> ./id_rsa
    echo "$SSH_PUBLIC_KEY" >> ./id_rsa.pub
    
    echo "Copying files into server"
    
    ssh -f ./id_rsa.pub $SERVER_USER@$SERVER_HOST "mkdir -p /opt/$SERVICE/"
    scp -f ./id_rsa.pub ./... $SERVER_USER@$SERVER_HOST:/opt/$SERVICE/
else
    echo "Error: directory $SERVICE not found. Can not continue."
    exit 1
fi
