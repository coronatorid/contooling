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
    chmod 700 id_rsa
    chmod 700 id_rsa.pub
    
    echo "========================================"
    
    
    
    
    echo "Gathering all services in docker-compose.yml."
    echo "========================================"
    
    all_service=$(yq r docker-compose.yml services | grep -v '^ .*' | sed 's/:.*$//' | xargs)
    
    # Excluding nginx
    echo "cd /opt/$SERVICE" > ./runner.sh
    echo all_service | perl -ne 'print "docker-compose up $_"' | sed 's/ nginx//' >> ./runner.sh
    
    echo "Creating services supervisor config"
    echo "[program:$SERVICE]
command=/opt/$SERVICE/runner.sh
autostart=true
autorestart=true
stderr_logfile=/var/log/$SERVICE.err.log
stdout_logfile=/var/log/$SERVICE.out.log
    " > ./supervisor.conf
    
    
    if [[ $all_service =~ "nginx" ]]; then
        echo "Creating nginx supervisor config"
        echo "[program:nginx_$SERVICE]
    command=/opt/nginx_$SERVICE/runner.sh
    autostart=true
    autorestart=true
    stderr_logfile=/var/log/nginx_$SERVICE.err.log
    stdout_logfile=/var/log/nginx_$SERVICE.out.log
        " > ./nginx_supervisor.conf
    fi
    
    
    echo "========================================"
    
    
    
    echo "Copying files into server"
    echo "========================================"
    
    ssh -i ./id_rsa $SERVER_USER@$SERVER_HOST "mkdir -p /opt/$SERVICE/"
    scp -i ./id_rsa -r $(pwd) $SERVER_USER@$SERVER_HOST:/opt/
    scp -i ./id_rsa ./supervisor.conf $SERVER_USER@$SERVER_HOST:/etc/supervisor/conf.d/$SERVICE.conf
    scp -i ./id_rsa ./nginx_supervisor.conf $SERVER_USER@$SERVER_HOST:/etc/supervisor/conf.d/nginx_$SERVICE.conf
else
    echo "Error: directory $SERVICE not found. Can not continue."
    exit 1
fi
