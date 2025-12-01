# Emergency Recovery Procedures

## Quick Reference

### Check Cluster Health
```bash
kubectl get nodes
kubectl get pods --all-namespaces
kubectl top nodes
```

### View Recent Events
```bash
kubectl get events --all-namespaces --sort-by='.lastTimestamp' | tail -50
```

### Check Service Status
```bash
kubectl get deployments --all-namespaces
kubectl get hpa --all-namespaces
kubectl get pdb --all-namespaces
```

## Common Failure Scenarios

### 1. Pods Stuck in Pending
**Symptoms:** Pods show `Pending` status

**Diagnosis:**
```bash
kubectl describe pod -n <namespace> <pod-name>
```

**Common Causes:**
- Insufficient resources
- Node selector mismatch
- PVC not bound
- Image pull failure

**Resolution:**
```bash
# Check resources
kubectl describe nodes

# Scale down non-critical services
kubectl scale deployment <name> -n <namespace> --replicas=1

# Check PVC
kubectl get pvc --all-namespaces

# Check image pull secrets
kubectl get secrets --all-namespaces | grep registry
```

### 2. Pods Crash Looping
**Symptoms:** Pods show `CrashLoopBackOff`

**Diagnosis:**
```bash
kubectl logs -n <namespace> <pod-name> --previous
kubectl describe pod -n <namespace> <pod-name>
```

**Resolution:**
```bash
# Check application logs
kubectl logs -n <namespace> -l app=<app-name> --tail=100

# Check liveness/readiness probes
kubectl get pod -n <namespace> <pod-name> -o yaml | grep -A 10 Probe

# Rollback if recent deployment
kubectl rollout undo deployment/<name> -n <namespace>
```

### 3. Service Not Responding
**Symptoms:** Service unreachable, 503 errors

**Diagnosis:**
```bash
kubectl get endpoints -n <namespace> <service-name>
kubectl get pods -n <namespace> -l app=<app-name>
```

**Resolution:**
```bash
# Check if pods are ready
kubectl get pods -n <namespace> -o wide

# Restart deployment
kubectl rollout restart deployment/<name> -n <namespace>

# Check network policies
kubectl get networkpolicies -n <namespace>
```

### 4. HPA Not Scaling
**Symptoms:** Load high but no new pods

**Diagnosis:**
```bash
kubectl describe hpa -n <namespace> <hpa-name>
kubectl top pods -n <namespace>
```

**Resolution:**
```bash
# Check metrics-server
kubectl get apiservices | grep metrics

# Restart metrics-server
kubectl rollout restart -n kube-system deployment/metrics-server

# Manually scale if needed
kubectl scale deployment <name> -n <namespace> --replicas=<number>
```

## Emergency Contacts
- On-Call Engineer: +XXX-XXX-XXXX
- Slack: #platform-alerts
- Email: ops-team@example.com