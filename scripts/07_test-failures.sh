#!/bin/bash
# Failure scenario testing script

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_test() { echo -e "${BLUE}[TEST]${NC} $1"; }

# Test 1: Pod Crash
test_pod_crash() {
    log_test "Scenario 1: Testing pod crash recovery..."
    
    echo "Initial pod status:"
    kubectl get pods -n api-service
    
    POD=$(kubectl get pods -n api-service -l app=api-service -o jsonpath='{.items[0].metadata.name}')
    log_info "Deleting pod: $POD"
    kubectl delete pod -n api-service $POD
    
    log_info "Waiting for new pod to be ready..."
    sleep 5
    kubectl wait --for=condition=ready pod -l app=api-service -n api-service --timeout=60s
    
    echo "New pod status:"
    kubectl get pods -n api-service
    
    log_info "✅ Pod crash recovery successful!"
}

# Test 2: Service Outage
test_service_outage() {
    log_test "Scenario 2: Testing complete service outage..."
    
    log_info "Scaling auth-service to 0..."
    kubectl scale deployment auth-service -n auth-service --replicas=0
    
    sleep 10
    
    log_info "Checking for alerts..."
    kubectl logs -n monitoring deployment/prometheus-alertmanager --tail=50 | grep -i auth || true
    
    log_info "Restoring auth-service..."
    kubectl scale deployment auth-service -n auth-service --replicas=2
    kubectl wait --for=condition=available deployment/auth-service -n auth-service --timeout=120s
    
    log_info "✅ Service outage recovery successful!"
}

# Test 3: Traffic Spike (Load Test)
test_traffic_spike() {
    log_test "Scenario 3: Testing HPA under load..."
    
    log_info "Current HPA status:"
    kubectl get hpa -n api-service
    
    log_info "Initial pod count:"
    kubectl get pods -n api-service
    
    log_info "Generating load (this will take 2 minutes)..."
    kubectl run -it --rm load-generator --image=busybox --restart=Never -- sh -c "
        while true; do
            wget -q -O- http://api-service.api-service:3000/health/live
        done
    " &
    
    LOAD_PID=$!
    
    log_info "Monitoring for 2 minutes..."
    for i in {1..12}; do
        sleep 10
        echo "Pods at ${i}0 seconds:"
        kubectl get pods -n api-service | grep api-service
        kubectl get hpa -n api-service | grep api-service
    done
    
    log_info "Stopping load generator..."
    kill $LOAD_PID || true
    
    log_info "Final pod count:"
    kubectl get pods -n api-service
    
    log_info "✅ HPA test completed!"
}

# Test 4: Network Policy Test
test_network_policy() {
    log_test "Scenario 4: Testing network policies..."
    
    log_info "Creating test pod in api-service namespace..."
    kubectl run test-pod -n api-service --image=busybox --restart=Never --rm -it -- sh -c "
        echo 'Testing auth-service connectivity...'
        wget -T 5 -O- http://auth-service.auth-service:8080/health/live
    " || log_warn "Connection blocked as expected"
    
    log_info "✅ Network policy test completed!"
}

# Test 5: Memory Stress
test_memory_stress() {
    log_test "Scenario 5: Testing memory limits..."
    
    log_info "Creating memory stress pod..."
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: memory-stress
  namespace: api-service
spec:
  containers:
  - name: stress
    image: polinux/stress
    resources:
      limits:
        memory: "128Mi"
      requests:
        memory: "64Mi"
    command: ["stress"]
    args: ["--vm", "1", "--vm-bytes", "150M", "--vm-hang", "1"]
EOF
    
    log_info "Monitoring pod (should be OOMKilled)..."
    sleep 30
    kubectl get pod memory-stress -n api-service
    kubectl describe pod memory-stress -n api-service | grep -A 5 "State:"
    
    log_info "Cleaning up..."
    kubectl delete pod memory-stress -n api-service --force --grace-period=0
    
    log_info "✅ Memory limit test completed!"
}

# Main menu
show_menu() {
    echo ""
    echo "================================================"
    echo "  Kubernetes Failure Scenario Testing"
    echo "================================================"
    echo "1) Pod Crash Recovery"
    echo "2) Complete Service Outage"
    echo "3) Traffic Spike (HPA Test)"
    echo "4) Network Policy Enforcement"
    echo "5) Memory Limit Test"
    echo "6) Run All Tests"
    echo "0) Exit"
    echo "================================================"
}

# Run specific test
run_test() {
    case $1 in
        1) test_pod_crash ;;
        2) test_service_outage ;;
        3) test_traffic_spike ;;
        4) test_network_policy ;;
        5) test_memory_stress ;;
        6) 
            test_pod_crash
            test_service_outage
            test_traffic_spike
            test_network_policy
            test_memory_stress
            ;;
        0) exit 0 ;;
        *) log_error "Invalid option" ;;
    esac
}

# If argument provided, run that test
if [ $# -gt 0 ]; then
    case $1 in
        pod-crash) run_test 1 ;;
        service-outage) run_test 2 ;;
        traffic-spike) run_test 3 ;;
        network-policy) run_test 4 ;;
        memory-stress) run_test 5 ;;
        all) run_test 6 ;;
        *) log_error "Unknown test: $1" ;;
    esac
    exit 0
fi

# Interactive mode
while true; do
    show_menu
    read -p "Select test to run: " choice
    run_test $choice
done
FAILURESCRIPT

chmod +x scripts/test-failures.sh