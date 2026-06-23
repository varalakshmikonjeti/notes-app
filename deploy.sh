#!/bin/bash

APP_IMAGE="notes-app"
PREV_IMAGE="notes-app-prev"
CONTAINER_NAME="notes-app-container"

rollback() {
    echo "Rolling back to previous version..."
    
    # Stop current broken container
    docker stop $CONTAINER_NAME || true
    docker rm $CONTAINER_NAME || true
    
    # Check if previous image exists
    if docker image inspect $PREV_IMAGE &>/dev/null; then
        echo "Previous image found. Starting rollback container..."
        docker run -d \
            --name $CONTAINER_NAME \
            --env-file .env \
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
    
    # Save previous image
    docker tag $APP_IMAGE $PREV_IMAGE || true
    
    # Stop existing container
    docker stop $CONTAINER_NAME || true
    docker rm $CONTAINER_NAME || true
    
    # Start new container
    docker run -d \
        --name $CONTAINER_NAME \
        --env-file .env \
        -p 5000:5000 \
        --restart unless-stopped \
        $APP_IMAGE
    
    echo "Deployment done!"
}

# Check argument
if [ "$1" = "rollback" ]; then
    rollback
else
    deploy
fi