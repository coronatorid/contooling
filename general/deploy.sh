#!/bin/bash

# Variable
# SERVICE = deployed services
# RELEASE_TAG = deployment tag of a services
# SSH_PRIVATE_KEY
# SSH_PUBLIC_KEY
# SERVER_USER
# SERVER_HOST
# DOCKER_PASSWORD
# DOCKER_USERNAME


echo "START DEPLOYMENT PROCESS"

if [ -z $SERVICE ] || [ -z $DOCKER_PASSWORD ] || [ -z $DOCKER_USERNAME ] || [ -z $RELEASE_TAG ] || [ -z $SSH_PRIVATE_KEY ] || [ -z $SSH_PUBLIC_KEY ]; then
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
    
    mkdir -p ~/.ssh && chmod 700 ~/.ssh && cd ~/.ssh/
    echo "$SSH_PRIVATE_KEY" >> ./id_rsa && echo "$SSH_PUBLIC_KEY" >> ./id_rsa.pub
    chmod 600 id_rsa && chmod 644 id_rsa.pub
    cat ./general/ssh-config-file > config && chmod 644 config
    
    echo "========================================"
    
    
    echo "Installing prerequisites"
    echo "========================================"
    sudo snap install yq
    sudo snap install jq
    
    
    echo "Gathering all services in docker-compose.yml."
    echo "========================================"
    
    all_service=$(yq r docker-compose.yml services | grep -v '^ .*' | sed 's/:.*$//' | xargs)
    
    echo "#!/bin/bash" > "./${SERVICE}_runner"
    echo "cd /opt/$SERVICE" >> "./${SERVICE}_runner"
    echo $all_service | perl -ne 'print "docker-compose up $_"' | sed 's/ nginx//' >> "./${SERVICE}_runner"
    
    echo "Creating services supervisor config"
    echo "[program:$SERVICE]
command=/opt/$SERVICE/${SERVICE}_runner
autostart=true
autorestart=true
stderr_logfile=/var/log/$SERVICE.err.log
stdout_logfile=/var/log/$SERVICE.out.log
user=root
    " > ./supervisor.conf
    
    
    if [[ $all_service =~ "nginx" ]]; then
        echo "#!/bin/bash" > "./${SERVICE}_nginx_runner"
        echo "cd /opt/$SERVICE" >> "./${SERVICE}_nginx_runner"
        echo "docker-compose up nginx" >> "./${SERVICE}_nginx_runner"
        
        echo "Creating nginx supervisor config"
        echo "[program:nginx_$SERVICE]
command=/opt/$SERVICE/${SERVICE}_nginx_runner
autostart=true
autorestart=true
stderr_logfile=/var/log/nginx_$SERVICE.err.log
stdout_logfile=/var/log/nginx_$SERVICE.out.log
user=root
        " > ./nginx_supervisor.conf
    fi
    
    
    echo "========================================"
    
    
    
    echo "Copying files into server"
    echo "========================================"
    
    ssh CoronatorMachine "mkdir -p /opt/$SERVICE/"
    scp -r $(pwd) CoronatorMachine:/opt/
    scp ./supervisor.conf CoronatorMachine:/etc/supervisor/conf.d/$SERVICE.conf
    scp ./nginx_supervisor.conf CoronatorMachine:/etc/supervisor/conf.d/nginx_$SERVICE.conf
    
    
    echo "========================================"
    echo "Modify file access"
    echo "========================================"
    ssh CoronatorMachine "chmod 700 -R /opt/$SERVICE/"
    echo "========================================"
    
    
    
    
    echo "========================================"
    echo "Login into ghcr.io"
    echo "========================================"
    ssh CoronatorMachine "echo $DOCKER_PASSWORD | sudo docker login ghcr.io -u $DOCKER_USERNAME --password-stdin"
    echo "========================================"
    
    echo "========================================"
    echo "Pulling image in remote server"
    echo "========================================"
    ssh CoronatorMachine "cd /opt/$SERVICE/ && docker-compose pull"
    echo "========================================"
    
    
    echo "========================================"
    echo "Create $SERVICE network in remote server"
    echo "========================================"
    ssh CoronatorMachine "docker network create -d bridge ${SERVICE}_default"
    echo "========================================"
    
    
    
    
    echo "========================================"
    echo "Rereading and updating supervisor"
    echo "========================================"
    ssh CoronatorMachine "supervisorctl reread && supervisorctl update"
    echo "========================================"
    
    
    
    
    echo "========================================"
    echo "Deploying $SERVICE services"
    echo "========================================"
    
    ssh CoronatorMachine "supervisorctl restart $SERVICE"
    
    echo "========================================"
    
    
    
    
    if [[ $all_service =~ "nginx" ]]; then
        echo "========================================"
        echo "Deploying nginx services"
        echo "========================================"
        
        nginx_status=$(ssh CoronatorMachine "docker container inspect ${SERVICE}_nginx | jq 'first.State.Status'")
        echo "NGINX STATUS: $nginx_status"
        
        if ! [ -z $nginx_status ] && [[ $nginx_status =~ "running" ]]; then
            echo "Nginx already running, restarting instead of docker-compose up"
            ssh CoronatorMachine "docker exec ${SERVICE}_nginx nginx -s reload"
        else
            echo "Restarting nginx with supervisor"
            ssh CoronatorMachine "supervisorctl restart nginx_$SERVICE"
        fi
        echo "========================================"
    fi
    
    
    echo "All deployment process is done."
else
    echo "Error: directory $SERVICE not found. Can not continue."
    exit 1
fi
