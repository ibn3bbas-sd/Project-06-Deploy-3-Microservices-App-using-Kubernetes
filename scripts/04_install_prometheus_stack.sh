#!/bin/bash

set -e

echo "==============================================="
echo "  Installing Prometheus + Grafana Stack (Helm)"
echo "==============================================="

### 1. Add Prometheus Helm Repository #####################################

echo "[1/3] Adding Prometheus Community Helm repo..."

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

echo "✔ Helm repo added & updated"


### 2. Create Monitoring Namespace #########################################

echo ""
echo "[2/3] Creating 'monitoring' namespace..."

kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

echo "✔ Namespace 'monitoring' is ready"


### 3. Install Kube-Prometheus-Stack #######################################

echo ""
echo "[3/3] Installing kube-prometheus-stack via Helm..."

helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false \
  --set grafana.adminPassword="admin123" \
  --set alertmanager.enabled=true

echo ""
echo "==============================================="
echo "  Prometheus Stack Installed Successfully!"
echo "==============================================="
echo "Grafana credentials:"
echo "  Username: admin"
echo "  Password: admin123"
echo "-----------------------------------------------"
echo "Grafana service:"
echo "  kubectl get svc -n monitoring | grep grafana"
echo "==============================================="
