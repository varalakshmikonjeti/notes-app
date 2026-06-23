#!/bin/bash

MAX_RETRIES=5
TIMEOUT=10
WAIT_BETWEEN=10

echo "Waiting 15s for app to start..."
sleep 15

# Get container IP
CONTAINER_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' notes-app-container)
HEALTH_URL="http://${CONTAINER_IP}:5000/health"

echo "Checking health at: $HEALTH_URL"
echo "Starting health check..."

for i in $(seq 1 $MAX_RETRIES); do
    echo "Attempt $i of $MAX_RETRIES..."
    
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" --max-time $TIMEOUT $HEALTH_URL)
    
    if [ "$RESPONSE" = "200" ]; then
        echo "Health check passed! App is healthy."
        exit 0
    else
        echo "Health check failed. Response code: $RESPONSE"
        if [ $i -lt $MAX_RETRIES ]; then
            echo "Waiting ${WAIT_BETWEEN}s before retry..."
            sleep $WAIT_BETWEEN
        fi
    fi
done

echo "All $MAX_RETRIES attempts failed. Triggering rollback..."
exit 1