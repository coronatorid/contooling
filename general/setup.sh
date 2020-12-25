#!/bin/bash

echo "Preparing instance for coronator infrastructure"
echo "==============================================="

cd

echo "Update repository"
echo "==============================================="

sudo apt update
sudo apt upgrade




echo "Installing prerequisites"
echo "==============================================="

sudo apt install apt-transport-https
sudo apt install ca-certificates
sudo apt install curl
sudo apt install gnupg-agent
sudo apt install software-properties-common
sudo snap install yq




echo "Installing docker"
echo "==============================================="

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io -y

echo "Docker version: $(docker --version)"
echo "-----------------------------------------------"



echo "Installing docker-compose"
echo "==============================================="

sudo curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

echo "Docker compose version: $(docker-compose --version)"
echo "-----------------------------------------------"



echo "Installing supervisor"
echo "==============================================="
sudo apt-get install supervisor -y
service supervisor restart
