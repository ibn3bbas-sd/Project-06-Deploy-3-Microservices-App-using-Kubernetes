#!/bin/bash
# Complete automated setup for local Kubernetes environment

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
log_info "Checking prerequisites..."

if ! command_exists kubectl; then
    log_error "kubectl is not installed. Please install kubectl first."
    exit 1
fi

if ! command_exists docker; then
    log_error "docker is not installed. Please install Docker first."
    exit 1
fi

if ! command_exists minikube; then
    log_warn "minikube not found. Installing..."
    # Installation instructions would go here
    log_error "Please install minikube manually: https://minikube.sigs.k8s.io/docs/start/"
    exit 1
fi

if ! command_exists helm; then
    log_warn "helm not found. Please install Helm: https://helm.sh/docs/intro/install/"
    exit 1
fi

# Start minikube
log_info "Starting minikube cluster..."
minikube start --cpus=4 --memory=8192 --driver=docker || {
    log_error "Failed to start minikube"
    exit 1
}

# Enable addons
log_info "Enabling minikube addons..."
minikube addons enable ingress
minikube addons enable metrics-server
minikube addons enable storage-provisioner

# Set kubectl context
kubectl config use-context minikube

# Create namespaces
log_info "Creating namespaces..."
kubectl apply -f k8s/00-namespaces.yaml

# Setup local registry
log_info "Setting up local Docker registry..."
if ! docker ps | grep -q registry; then
    docker run -d -p 5000:5000 --restart=always --name registry registry:2
fi

# Build and push images
log_info "Building Docker images..."
export REGISTRY=localhost:5000

# Build API Service
log_info "Building API Service..."
docker build -t ${REGISTRY}/api-service:latest ./api-service
docker push ${REGISTRY}/api-service:latest

# Build Auth Service
log_info "Building Auth Service..."
docker build -t ${REGISTRY}/auth-service:latest ./auth-service
docker push ${REGISTRY}/auth-service:latest

# Build Image Service
log_info "Building Image Service..."
docker build -t ${REGISTRY}/image-service:latest ./image-service
docker push ${REGISTRY}/image-service:latest

# Generate secrets
log_info "Generating secrets..."
DB_PASSWORD=$(openssl rand -base64 32)
JWT_SECRET=$(openssl rand -base64 64)
S3_ACCESS_KEY="minioadmin"
S3_SECRET_KEY="minioadmin"

# Create secrets
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
  namespace: api-service
type: Opaque
stringData:
  username: apiuser
  password: "${DB_PASSWORD}"
  database: apidb
  host: postgresql.default.svc.cluster.local
---
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
  namespace: auth-service
type: Opaque
stringData:
  username: authuser
  password: "${DB_PASSWORD}"
  database: authdb
  host: postgresql.default.svc.cluster.local
---
apiVersion: v1
kind: Secret
metadata:
  name: jwt-secret
  namespace: auth-service
type: Opaque
stringData:
  secret-key: "${JWT_SECRET}"
---
apiVersion: v1
kind: Secret
metadata:
  name: s3-credentials
  namespace: image-service
type: Opaque
stringData:
  access-key: "${S3_ACCESS_KEY}"
  secret-key: "${S3_SECRET_KEY}"
  endpoint: http://minio.default.svc.cluster.local:9000
  bucket: images
EOF

# Deploy ConfigMaps
log_info "Deploying ConfigMaps..."
kubectl apply -f k8s/02-configmaps.yaml

# Deploy supporting services (PostgreSQL, MinIO)
log_info "Deploying PostgreSQL..."
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install postgresql bitnami/postgresql \
  --namespace default \
  --set auth.password=${DB_PASSWORD} \
  --set primary.persistence.size=5Gi

log_info "Deploying MinIO..."
helm install minio bitnami/minio \
  --namespace default \
  --set auth.rootUser=${S3_ACCESS_KEY} \
  --set auth.rootPassword=${S3_SECRET_KEY} \
  --set persistence.size=10Gi

# Wait for databases to be ready
log_info "Waiting for databases to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=postgresql --timeout=300s
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=minio --timeout=300s

# Deploy microservices
log_info "Deploying microservices..."
# Update image references to use local registry
sed -i.bak "s|your-registry.io|${REGISTRY}|g" k8s/03-api-deployment.yaml
sed -i.bak "s|your-registry.io|${REGISTRY}|g" k8s/04-auth-deployment.yaml
sed -i.bak "s|your-registry.io|${REGISTRY}|g" k8s/05-image-deployment.yaml

kubectl apply -f k8s/03-api-deployment.yaml
kubectl apply -f k8s/04-auth-deployment.yaml
kubectl apply -f k8s/05-image-deployment.yaml
kubectl apply -f k8s/06-services.yaml

# Wait for deployments
log_info "Waiting for services to be ready..."
kubectl wait --for=condition=available deployment/api-service -n api-service --timeout=300s
kubectl wait --for=condition=available deployment/auth-service -n auth-service --timeout=300s
kubectl wait --for=condition=available deployment/image-service -n image-service --timeout=300s

# Apply network policies
log_info "Applying network policies..."
kubectl apply -f k8s/07-network-policies.yaml

# Setup autoscaling
log_info "Setting up autoscaling..."
kubectl apply -f k8s/08-hpa.yaml
kubectl apply -f k8s/09-pdb.yaml

# Install monitoring stack
log_info "Installing Prometheus monitoring stack..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set grafana.adminPassword=admin123 \
  --wait \
  --timeout=10m

# Deploy custom monitoring configs
log_info "Deploying custom monitoring configurations..."
kubectl apply -f k8s/monitoring/servicemonitors.yaml
kubectl apply -f k8s/monitoring/prometheus-rules.yaml

# Setup ingress
log_info "Setting up ingress..."
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: main-ingress
  namespace: api-service
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: nginx
  rules:
  - host: api.local.dev
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 3000
EOF

# Get minikube IP
MINIKUBE_IP=$(minikube ip)

# Print success message
log_info "✅ Setup complete!"
echo ""
echo "================================================"
echo "  Kubernetes Microservices Environment Ready"
echo "================================================"
echo ""
echo "Cluster Information:"
echo "  Minikube IP: ${MINIKUBE_IP}"
echo "  Kubernetes Version: $(kubectl version --short 2>/dev/null | grep Server || echo 'N/A')"
echo ""
echo "Add this to your /etc/hosts file:"
echo "  ${MINIKUBE_IP} api.local.dev"
echo ""
echo "Access URLs:"
echo "  API Service: http://api.local.dev"
echo "  Grafana: kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
echo "    Then open: http://localhost:3000 (admin/admin123)"
echo "  Prometheus: kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090"
echo "    Then open: http://localhost:9090"
echo ""
echo "Service Status:"
kubectl get pods -n api-service
kubectl get pods -n auth-service
kubectl get pods -n image-service
echo ""
echo "HPA Status:"
kubectl get hpa --all-namespaces
echo ""
echo "Quick Commands:"
echo "  View all pods: kubectl get pods -A"
echo "  View logs: kubectl logs -n <namespace> -l app=<app-name> -f"
echo "  Access Grafana: kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
echo "  Run tests: ./scripts/test-failures.sh"
echo ""
echo "================================================"