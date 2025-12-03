#!/bin/bash

set -e
set -o pipefail

echo "=============================================="
echo "🔍 VERIFICATION COMMANDS"
echo "=============================================="

### ----------------------------------------------
echo "📦 Checking all resources in namespaces..."
### ----------------------------------------------
kubectl get all -n api-service
kubectl get all -n auth-service
kubectl get all -n image-service

echo "----------------------------------------------"
echo "📈 Checking HPA status..."
echo "----------------------------------------------"
kubectl get hpa -A

echo "----------------------------------------------"
echo "🛡 Checking PodDisruptionBudgets..."
echo "----------------------------------------------"
kubectl get pdb -A

echo "----------------------------------------------"
echo "🌐 Checking Network Policies..."
echo "----------------------------------------------"
kubectl get networkpolicies -A

echo "----------------------------------------------"
echo "🌍 Checking Ingress..."
echo "----------------------------------------------"
kubectl get ingress -A

echo "----------------------------------------------"
echo "🔏 Checking TLS Certificates..."
echo "----------------------------------------------"
kubectl get certificates -A


### ----------------------------------------------
echo "📜 LOGS"
echo "----------------------------------------------"

echo "Fetching API service logs..."
kubectl logs -f -n api-service deployment/api-service &
sleep 2

echo "Fetching Auth service logs..."
kubectl logs -f -n auth-service deployment/auth-service &
sleep 2

echo "Fetching Image service logs..."
kubectl logs -f -n image-service deployment/image-service &
sleep 2


### ----------------------------------------------
echo "📊 Checking Metrics..."
echo "----------------------------------------------"
kubectl top pods -n api-service || echo "⚠️ Metrics not available"
kubectl top pods -n auth-service || echo "⚠️ Metrics not available"
kubectl top pods -n image-service || echo "⚠️ Metrics not available"


echo "=============================================="
echo "🌐 ACCESS SERVICES"
echo "=============================================="

if command -v minikube &> /dev/null; then
  echo "🔍 Detecting Minikube IP..."
  MINIKUBE_IP=$(minikube ip)
  echo "Minikube IP: $MINIKUBE_IP"

  echo "----------------------------------------------"
  echo "🖥 Linux users: update /etc/hosts"
  echo "----------------------------------------------"
  echo "Run:"
  echo "echo \"$MINIKUBE_IP api.local.dev\" | sudo tee -a /etc/hosts"

  echo "----------------------------------------------"
  echo "🖥 Windows users: Edit hosts file manually:"
  echo "----------------------------------------------"
  echo "C:\\Windows\\System32\\drivers\\etc\\hosts"
  echo "$MINIKUBE_IP api.local.dev"

  echo "----------------------------------------------"
  echo "🌍 Test API endpoint:"
  echo "----------------------------------------------"
  echo "curl https://api.local.dev"
else
  echo "⚠️ Minikube not detected — skipping minikube IP section."
fi


echo "=============================================="
echo "🧪 PORT FORWARDING (Testing)"
echo "=============================================="

echo "Run these commands in separate terminals when needed:"
echo ""
echo "# API Service"
echo "kubectl port-forward -n api-service svc/api-service 3000:3000"
echo ""
echo "# Auth Service"
echo "kubectl port-forward -n auth-service svc/auth-service 8080:8080"
echo ""
echo "# Image Service"
echo "kubectl port-forward -n image-service svc/image-service 8000:8000"
echo ""
echo "# Grafana"
echo "kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
echo ""
echo "# Prometheus"
echo "kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090"

echo ""
echo "======================================================="
echo "🎉 VERIFICATION & ACCESS COMMANDS EXECUTED SUCCESSFULLY"
echo "======================================================="
