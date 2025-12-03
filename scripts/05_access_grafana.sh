#!/bin/bash

set -e

echo "==============================================="
echo "        Access Grafana (Port-Forward)"
echo "==============================================="

NAMESPACE="monitoring"
SERVICE_NAME="prometheus-grafana"
LOCAL_PORT=3000
SERVICE_PORT=80
USERNAME="admin"
PASSWORD="admin123"   # Change if you used a custom password

echo "[1/2] Checking if Grafana service exists..."

if ! kubectl get svc -n "$NAMESPACE" | grep -q "$SERVICE_NAME"; then
  echo "✘ Grafana service '$SERVICE_NAME' not found in namespace '$NAMESPACE'"
  exit 1
fi

echo "✔ Grafana service found"


echo ""
echo "[2/2] Starting port-forward..."
echo "-----------------------------------------------"
echo "Open your browser at: http://localhost:$LOCAL_PORT"
echo ""
echo "Login:"
echo "  Username: $USERNAME"
echo "  Password: $PASSWORD"
echo "-----------------------------------------------"
echo "Press CTRL+C to stop port-forwarding"
echo "==============================================="

kubectl port-forward -n "$NAMESPACE" svc/"$SERVICE_NAME" $LOCAL_PORT:$SERVICE_PORT
