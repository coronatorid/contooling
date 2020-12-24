#!/bin/bash

# Variable
# SERVICE = deployed services

echo "START DEPLOYMENT PROCESS"

if [ -d "../$SERVICE" ]; then
  echo "Deploying $SERVICE"
  echo "Change directory to respective services"

  cd ../$SERVICE

  echo "Showing all files in directory"
  echo "========================================"
  ls -la
  echo "========================================"

  echo "TAG=$RELEASE_TAG" >> .env
else
  echo "Error: directory $SERVICE not found. Can not continue."
  exit 1
fi
