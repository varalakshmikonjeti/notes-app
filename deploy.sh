#!/bin/bash

APP_IMAGE="notes-app"
PREV_IMAGE="notes-app-prev"
CONTAINER_NAME="notes-app-container"
DATABASE_URL="${DATABASE_URL}"

rollback() {
    echo "Rolling back to previous version..."
    
    docker stop $CONTAINER_NAME || true
    docker rm $CONTAINER_NAME || true
    
    if docker image inspect $PREV_IMAGE &>/dev/null; then
        echo "Previous image found. Starting rollback container..."
        docker run -d \
            --name $CONTAINER_NAME \
            -e DATABASE_URL=$DATABASE_URL \
            -p 5000:5000 \
            --restart unless-stopped \
            $PREV_IMAGE
        echo "Rollback complete!"
    else
        echo "No previous image found. Cannot rollback!"
        exit 1
    fi
}

deploy() {
    echo "Deploying new version..."
    
    docker tag $APP_IMAGE $PREV_IMAGE || true
    docker stop $CONTAINER_NAME || true
    docker rm $CONTAINER_NAME || true
    
    docker run -d \
        --name $CONTAINER_NAME \
        -e DATABASE_URL=$DATABASE_URL \
        -p 5000:5000 \
        --restart unless-stopped \
        $APP_IMAGE
    
    echo "Deployment done!"
}

if [ "$1" = "rollback" ]; then
    rollback
else
    deploy
fi