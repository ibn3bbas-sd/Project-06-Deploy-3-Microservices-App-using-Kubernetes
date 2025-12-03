#!/bin/bash

set -e

echo "========================================"
echo " Create Docker Registry Secret (YAML)"
echo "========================================"

# ---------- USER INPUT VARIABLES ----------
REGISTRY_SERVER="your-registry.io"
REGISTRY_USERNAME="your-username"
REGISTRY_PASSWORD="your-password"
REGISTRY_EMAIL="your-email"
NAMESPACE="api-service"

# ---------- GENERATE SECRET YAML ----------
echo "Generating docker-registry secret YAML..."

kubectl create secret docker-registry registry-credentials \
  --docker-server="$REGISTRY_SERVER" \
  --docker-username="$REGISTRY_USERNAME" \
  --docker-password="$REGISTRY_PASSWORD" \
  --docker-email="$REGISTRY_EMAIL" \
  --namespace="$NAMESPACE" \
  --dry-run=client -o yaml > registry-secret.yaml

echo "✔ Secret generated: registry-secret.yaml"
echo "========================================"
echo "You can apply it using:"
echo "kubectl apply -f registry-secret.yaml"
