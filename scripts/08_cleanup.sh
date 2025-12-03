#!/bin/bash
# Cleanup script

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

log_warn "This will delete all resources. Are you sure? (yes/no)"
read -r response

if [ "$response" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

log_info "Deleting all deployments..."
kubectl delete -f k8s/03-api-deployment.yaml || true
kubectl delete -f k8s/04-auth-deployment.yaml || true
kubectl delete -f k8s/05-image-deployment.yaml || true
kubectl delete -f k8s/06-services.yaml || true
kubectl delete -f k8s/07-network-policies.yaml || true
kubectl delete -f k8s/08-hpa.yaml || true
kubectl delete -f k8s/09-pdb.yaml || true

log_info "Uninstalling Helm releases..."
helm uninstall prometheus -n monitoring || true
helm uninstall postgresql -n default || true
helm uninstall minio -n default || true

log_info "Deleting namespaces..."
kubectl delete namespace api-service || true
kubectl delete namespace auth-service || true
kubectl delete namespace image-service || true
kubectl delete namespace monitoring || true

log_info "Stopping local registry..."
docker stop registry || true
docker rm registry || true

log_info "Stopping minikube..."
minikube stop

log_info "✅ Cleanup complete!"
CLEANUPSCRIPT

chmod +x scripts/cleanup.sh

log_info "All automation scripts created successfully!"