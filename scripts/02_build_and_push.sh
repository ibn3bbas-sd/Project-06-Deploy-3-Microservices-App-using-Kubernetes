#!/bin/bash

# Configuration
REGISTRY="docker.io/ibn3bbas"  # Replace with your registry 
VERSION="1.0.0"

# Build images
echo "Building images..."
docker build -t ${REGISTRY}/api-service:${VERSION} ./api-service
docker build -t ${REGISTRY}/auth-service:${VERSION} ./auth-service
docker build -t ${REGISTRY}/image-service:${VERSION} ./image-service

# Tag as latest
docker tag ${REGISTRY}/api-service:${VERSION} ${REGISTRY}/api-service:latest
docker tag ${REGISTRY}/auth-service:${VERSION} ${REGISTRY}/auth-service:latest
docker tag ${REGISTRY}/image-service:${VERSION} ${REGISTRY}/image-service:latest

# Login to registry
echo "Logging in to registry..."
docker login ${REGISTRY}

# Push images
echo "Pushing images..."
docker push ${REGISTRY}/api-service:${VERSION}
docker push ${REGISTRY}/api-service:latest
docker push ${REGISTRY}/auth-service:${VERSION}
docker push ${REGISTRY}/auth-service:latest
docker push ${REGISTRY}/image-service:${VERSION}
docker push ${REGISTRY}/image-service:latest

echo "Build and push complete!"