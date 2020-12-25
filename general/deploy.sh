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

if [ -z $SERVICE ] || [ -z $DOCKER_PASSWORD ] || [ -z $DOCKER_USERNAME ] || [ -z $RELEASE_TAG ] || [ -z $SSH_PRIVATE_KEY ] || [ -z $SSH_PUBLIC_KEY ] || [ -z $SERVER_USER ] || [ -z $SERVER_HOST ]; then
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
    
    ssh -i ./id_rsa $SERVER_USER@$SERVER_HOST "mkdir -p /opt/$SERVICE/"
    scp -i ./id_rsa -r $(pwd) $SERVER_USER@$SERVER_HOST:/opt/
    scp -i ./id_rsa ./supervisor.conf $SERVER_USER@$SERVER_HOST:/etc/supervisor/conf.d/$SERVICE.conf
    scp -i ./id_rsa ./nginx_supervisor.conf $SERVER_USER@$SERVER_HOST:/etc/supervisor/conf.d/nginx_$SERVICE.conf
    
    echo "Modify file access"
    ssh -i ./id_rsa $SERVER_USER@$SERVER_HOST "chmod 700 -R /opt/$SERVICE/"
    
    echo "Login into ghcr.io"
    ssh -i ./id_rsa $SERVER_USER@$SERVER_HOST "echo $DOCKER_PASSWORD | sudo docker login ghcr.io -u $DOCKER_USERNAME --password-stdin"
    
    echo "Rereading and updating supervisor"
    ssh -i ./id_rsa $SERVER_USER@$SERVER_HOST "supervisorctl reread && supervisorctl update"
    
    
    
    
    echo "========================================"
    echo "Deploying $SERVICE services"
    echo "========================================"
    
    ssh -i ./id_rsa $SERVER_USER@$SERVER_HOST "supervisorctl restart $SERVICE"
    
    echo "========================================"
    
    
    
    
    if [[ $all_service =~ "nginx" ]]; then
        echo "========================================"
        echo "Deploying nginx services"
        echo "========================================"
        
        nginx_status=$(ssh -i ./id_rsa $SERVER_USER@$SERVER_HOST "docker container inspect ${SERVICE}_nginx | jq 'first.State.Status'")
        
        if [[ -z $nginx_status && $nginx_status == "running" ]]; then
            echo "Nginx already running, restarting instead of docker-compose up"
            ssh -i ./id_rsa $SERVER_USER@$SERVER_HOST "docker exec ${SERVICE}_nginx nginx -s reload"
        else
            echo "Restarting nginx with supervisor"
            ssh -i ./id_rsa $SERVER_USER@$SERVER_HOST "supervisorctl restart nginx_$SERVICE"
        fi
        echo "========================================"
    fi
    
    
    echo "All deployment process is done."
else
    echo "Error: directory $SERVICE not found. Can not continue."
    exit 1
fi
