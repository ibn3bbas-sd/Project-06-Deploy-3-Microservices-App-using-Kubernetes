#!/bin/bash

set -e

echo "========================================"
echo " Kubernetes Environment Setup Script"
echo "========================================"

### 1. CHECK REQUIRED TOOLS ###############################################

echo "[1/3] Checking required tools..."

# Check kubectl
if command -v kubectl &> /dev/null; then
    echo "✔ kubectl installed: $(kubectl version --client --short)"
else
    echo "✘ kubectl not found! Install it first."
    exit 1
fi

# Check Docker
if command -v docker &> /dev/null; then
    echo "✔ Docker installed: $(docker --version)"
else
    echo "✘ Docker not found! Install Docker first."
    exit 1
fi

# Check Helm
if command -v helm &> /dev/null; then
    echo "✔ Helm installed: $(helm version --short)"
else
    echo "✘ Helm not found! Install Helm first."
    exit 1
fi


### 2. START MINIKUBE CLUSTER #############################################

echo ""
echo "[2/3] Starting Minikube cluster..."

minikube start --cpus=4 --memory=8192 --driver=docker

echo "✔ Minikube cluster started"


### 3. ENABLE REQUIRED ADDONS ##############################################

echo ""
echo "[3/3] Enabling Minikube addons..."

minikube addons enable ingress
minikube addons enable metrics-server
minikube addons enable storage-provisioner

echo ""
echo "========================================"
echo " Kubernetes Environment Ready!"
echo "========================================"
echo "Use: kubectl get nodes"
echo "========================================"
