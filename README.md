# Kubernetes Microservices Deployment Project

## 📋 Table of Contents
1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Quick Start](#quick-start)
5. [Detailed Setup](#detailed-setup)
6. [Monitoring & Alerts](#monitoring--alerts)
7. [Failure Scenarios](#failure-scenarios)
8. [Troubleshooting](#troubleshooting)
9. [Lessons Learned](#lessons-learned)
10. [Future Improvements](#future-improvements)

---

## 🎯 Project Overview

This project implements a production-grade Kubernetes deployment for a microservices architecture consisting of three services:

1. **API Service** (Node.js/Express) - Main application gateway
2. **Auth Service** (Go/Gin) - Authentication and authorization
3. **Image Service** (Python/FastAPI) - Image upload/storage with S3

### Key Features
- ✅ Complete service isolation with namespaces
- ✅ Network policies for security
- ✅ Automatic scaling (HPA) based on metrics
- ✅ Advanced monitoring with Prometheus & Grafana
- ✅ AlertManager integration (Slack, Email)
- ✅ TLS/SSL with Let's Encrypt
- ✅ Comprehensive failure scenarios tested
- ✅ Pod disruption budgets for high availability
- ✅ Health checks and readiness probes
- ✅ Secrets management
- ✅ Resource quotas and limits

---

## 🏗️ Architecture

### High-Level Architecture

```
Internet → Ingress (TLS) → API Service → Auth Service
                                       → Image Service → S3/MinIO
                                       
All Services → Prometheus → Grafana
            → AlertManager → Slack/Email
```

### Service Communication Flow

1. **External Request** → Ingress Controller (HTTPS/TLS)
2. **Ingress** → API Service (validates route, terminates SSL)
3. **API Service** → Auth Service (JWT validation)
4. **API Service** → Image Service (image operations)
5. **All Services** → PostgreSQL (persistent data)
6. **All Services** → Prometheus (metrics export)

### Network Architecture

```yaml
Namespaces:
  - api-service      (API pods, 3-10 replicas)
  - auth-service     (Auth pods, 2-8 replicas)
  - image-service    (Image pods, 2-15 replicas)
  - monitoring       (Prometheus, Grafana, AlertManager)

Network Policies:
  - API can talk to Auth & Image services
  - Auth can only talk to Database
  - Image can talk to S3 and Database
  - Monitoring can scrape all namespaces
  - All can access DNS
```

---

## 📦 Prerequisites

### Required Tools

```bash
# Kubernetes cluster (choose one)
- minikube >= 1.30
- kind >= 0.20
- GKE, EKS, or AKS cluster

# CLI Tools
kubectl >= 1.28
docker >= 24.0
helm >= 3.12

# Optional but recommended
k9s >= 0.27      # Cluster management TUI
kubectx          # Context switching
stern            # Multi-pod log tailing
```

### System Requirements

**For local development (minikube/kind):**
- CPU: 4+ cores
- RAM: 8GB+ available
- Disk: 20GB+ free space

**For production:**
- 3+ worker nodes
- 4 CPU, 16GB RAM per node minimum
- SSD storage

---

## 🚀 Quick Start

### One-Command Setup (Local Development)

```bash
# Clone repository
git clone https://github.com/ibn3bbas-sd/Project-06-Deploy-3-Microservices-App-using-Kubernetes.git
cd kubernetes-microservices

# Run automated setup
./scripts/00_setup_local.sh
```

This script will:
1. Start minikube cluster
2. Build Docker images locally
3. Deploy all services
4. Install monitoring stack
5. Setup ingress and networking
6. Display access URLs

### Access Services

```bash
# Get cluster IP (minikube)
minikube ip

# Add to /etc/hosts
echo "$(minikube ip) api.local.dev" | sudo tee -a /etc/hosts

# Access API
curl https://api.local.dev/health/live

# Access Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# Open http://localhost:3000 (admin/admin123)

# Access Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Open http://localhost:9090
```

---

## 🔧 Detailed Setup

### Step 1: Prepare Environment

```bash
# Create project directory structure
mkdir -p {api-service,auth-service,image-service,k8s/{monitoring,scripts}}

# Copy service code
cp -r src/api-service/* api-service/
cp -r src/auth-service/* auth-service/
cp -r src/image-service/* image-service/
```

### Step 2: Configure Secrets

```bash
# Generate strong passwords
DB_PASSWORD=$(openssl rand -base64 32)
JWT_SECRET=$(openssl rand -base64 64)
S3_ACCESS_KEY=$(openssl rand -base64 16)
S3_SECRET_KEY=$(openssl rand -base64 32)

# Create secrets file from template
cp k8s/01-secrets.yaml.template k8s/01-secrets.yaml

# Replace placeholders
sed -i "s/DB_PASSWORD_PLACEHOLDER/$DB_PASSWORD/g" k8s/01-secrets.yaml
sed -i "s/JWT_SECRET_PLACEHOLDER/$JWT_SECRET/g" k8s/01-secrets.yaml
sed -i "s/S3_ACCESS_KEY_PLACEHOLDER/$S3_ACCESS_KEY/g" k8s/01-secrets.yaml
sed -i "s/S3_SECRET_KEY_PLACEHOLDER/$S3_SECRET_KEY/g" k8s/01-secrets.yaml
```

### Step 3: Build and Push Images

**For local registry:**
```bash
# Start local registry
docker run -d -p 5000:5000 --name registry registry:2

# Set registry
export REGISTRY=localhost:5000

# Build and push
./scripts/02_build_and_push.sh
```

**For Docker Hub:**
```bash
# Login
docker login

# Set registry
export REGISTRY=your-dockerhub-username

# Build and push
./scripts/02_build_and_push.sh
```

**For private registry:**
```bash
# Login to registry
docker login your-registry.io

# Set registry
export REGISTRY=your-registry.io

# Build and push
./scripts/build-and-push.sh

# Create pull secret
kubectl create secret docker-registry registry-credentials \
  --docker-server=your-registry.io \
  --docker-username=your-username \
  --docker-password=your-password \
  --docker-email=your-email \
  -n api-service

# Repeat for other namespaces
```

### Step 4: Deploy Infrastructure

```bash
# Deploy in order
kubectl apply -f k8s/00-namespaces.yaml
kubectl apply -f k8s/01-secrets.yaml
kubectl apply -f k8s/02-configmaps.yaml

# Wait for namespaces to be active
kubectl get namespaces

# Deploy services
kubectl apply -f k8s/03-api-deployment.yaml
kubectl apply -f k8s/04-auth-deployment.yaml
kubectl apply -f k8s/05-image-deployment.yaml
kubectl apply -f k8s/06-services.yaml

# Wait for pods to be ready
kubectl wait --for=condition=ready pod -l app=api-service -n api-service --timeout=300s
kubectl wait --for=condition=ready pod -l app=auth-service -n auth-service --timeout=300s
kubectl wait --for=condition=ready pod -l app=image-service -n image-service --timeout=300s
```

### Step 5: Configure Networking

```bash
# Apply network policies
kubectl apply -f k8s/07-network-policies.yaml

# Verify policies
kubectl get networkpolicies --all-namespaces
```

### Step 6: Setup Autoscaling

```bash
# Deploy HPA
kubectl apply -f k8s/08-hpa.yaml

# Deploy PDB
kubectl apply -f k8s/09-pdb.yaml

# Verify HPA
kubectl get hpa --all-namespaces

# Verify PDB
kubectl get pdb --all-namespaces
```

### Step 7: Install Monitoring

```bash
# Install Prometheus stack
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set grafana.adminPassword=admin123

# Wait for monitoring stack
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n monitoring --timeout=300s

# Deploy custom monitoring configs
kubectl apply -f k8s/monitoring/servicemonitors.yaml
kubectl apply -f k8s/monitoring/prometheus-rules.yaml
kubectl apply -f k8s/monitoring/alertmanager-config.yaml
```

### Step 8: Setup Ingress & TLS

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Wait for cert-manager
kubectl wait --for=condition=Available deployment/cert-manager -n cert-manager --timeout=300s

# Update domain in ingress file
sed -i 's/yourdomain.com/your-actual-domain.com/g' k8s/10-ingress.yaml

# Deploy ingress
kubectl apply -f k8s/10-ingress.yaml

# Check certificate status
kubectl get certificates --all-namespaces
```

### Step 9: Apply Resource Limits

```bash
# Apply resource quotas
kubectl apply -f k8s/11-resource-quotas.yaml

# Verify quotas
kubectl get resourcequotas --all-namespaces
```

---

## 📊 Monitoring & Alerts

### Access Monitoring Dashboards

**Grafana:**
```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# URL: http://localhost:3000
# Username: admin
# Password: admin123
```

**Prometheus:**
```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

# URL: http://localhost:9090
```

**AlertManager:**
```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093

# URL: http://localhost:9093
```

### Key Metrics to Monitor

1. **Service Health**
   - Pod availability
   - Request success rate
   - Response time (p50, p95, p99)

2. **Resource Utilization**
   - CPU usage per service
   - Memory usage per service
   - Network I/O

3. **Scaling Metrics**
   - Current replica count
   - HPA target vs actual
   - Scale-up/down events

4. **Error Rates**
   - HTTP 5xx errors
   - Connection failures
   - Database errors

### Prometheus Queries

```promql
# Request rate per service
rate(http_requests_total{namespace="api-service"}[5m])

# Error rate
rate(http_requests_total{namespace="api-service",status_code=~"5.."}[5m])

# 95th percentile response time
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{namespace="api-service"}[5m]))

# Pod count
count(kube_pod_info{namespace="api-service"})

# CPU usage
rate(container_cpu_usage_seconds_total{namespace="api-service"}[5m])

# Memory usage
container_memory_usage_bytes{namespace="api-service"}
```

### Alert Configuration

Alerts are configured to fire on:

**Critical Alerts:**
- Service completely down (all pods unavailable)
- Error rate > 5%
- Database connection failure
- S3 connection failure

**Warning Alerts:**
- High CPU (> 70%)
- High memory (> 80%)
- Slow response time (p95 > 2s)
- Pod restarts

**Alert Destinations:**
- Slack: #alerts, #critical-alerts
- Email: ops-team@example.com
- PagerDuty: (configure in AlertManager)

---

## 💥 Failure Scenarios

### Tested Scenarios

| Scenario | Description | Status |
|----------|-------------|--------|
| Pod Crash | Single pod killed | ✅ Passed |
| Service Outage | All pods of service down | ✅ Passed |
| Database Failure | DB connection lost | ✅ Passed |
| Traffic Spike | 10x normal load | ✅ Passed |
| S3 Outage | Object storage unavailable | ✅ Passed |
| Network Partition | Service-to-service blocked | ✅ Passed |
| Node Failure | Entire node down | ✅ Passed |
| Memory Leak | OOM condition | ✅ Passed |

### Running Failure Tests

```bash
# Run all scenarios
./scripts/08_test_failures.sh

# Run specific scenario
./scripts/08_test_failures.sh pod-crash
./scripts/08_test_failures.sh traffic-spike
./scripts/08_test_failures.sh db-failure

# View results
cat failure-test-results.log
```

### Example: Pod Crash Test

```bash
# Kill random pod
POD=$(kubectl get pods -n api-service -l app=api-service -o name | head -1)
kubectl delete -n api-service $POD

# Monitor recovery
watch kubectl get pods -n api-service

# Expected: New pod created within 15 seconds
# Expected: Service remains available throughout
```

---

## 🔍 Troubleshooting

### Common Issues

#### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n <namespace>

# Describe pod to see errors
kubectl describe pod -n <namespace> <pod-name>

# Check logs
kubectl logs -n <namespace> <pod-name>

# Common causes:
# - Image pull failure → Check registry credentials
# - Insufficient resources → Check node resources
# - Failed liveness probe → Check application health
```

#### Services Not Accessible

```bash
# Check service endpoints
kubectl get endpoints -n <namespace>

# Check if pods are ready
kubectl get pods -n <namespace> -o wide

# Test connectivity from another pod
kubectl run -it --rm debug --image=busybox --restart=Never -- sh
wget -O- http://api-service.api-service:3000/health/live

# Check network policies
kubectl get networkpolicies -n <namespace>
```

#### HPA Not Scaling

```bash
# Check HPA status
kubectl describe hpa -n <namespace> <hpa-name>

# Check metrics availability
kubectl top pods -n <namespace>

# Verify metrics-server
kubectl get apiservices | grep metrics

# Restart metrics-server if needed
kubectl rollout restart -n kube-system deployment/metrics-server
```

#### Certificate Issues

```bash
# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager

# Check certificate status
kubectl describe certificate -n <namespace> <cert-name>

# Check issuer
kubectl describe clusterissuer letsencrypt-prod

# Manual renewal
kubectl delete certificate -n <namespace> <cert-name>
kubectl apply -f k8s/10-ingress.yaml
```

### Debugging Commands

```bash
# View all resources in namespace
kubectl get all -n <namespace>

# View recent events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# View pod logs (all containers)
kubectl logs -n <namespace> <pod-name> --all-containers=true

# Follow logs from multiple pods
kubectl logs -n <namespace> -l app=<app-name> -f

# Execute command in pod
kubectl exec -it -n <namespace> <pod-name> -- /bin/sh

# Port forward for debugging
kubectl port-forward -n <namespace> <pod-name> 8080:8080

# View resource usage
kubectl top nodes
kubectl top pods -n <namespace>

# Check RBAC permissions
kubectl auth can-i --list --as=system:serviceaccount:<namespace>:<sa-name>
```

---

## 📚 Lessons Learned

### What Worked Well

1. **Namespace Isolation**
   - Clear separation of concerns
   - Easier to apply policies and quotas
   - Better security posture

2. **Health Checks**
   - Liveness and readiness probes caught issues early
   - Prevented bad deployments from affecting users
   - Enabled zero-downtime deployments

3. **HPA**
   - Handled traffic spikes automatically
   - Reduced manual intervention
   - Optimized resource usage

4. **PodDisruptionBudgets**
   - Maintained availability during updates
   - Prevented cascading failures
   - Enabled safe node maintenance

5. **Monitoring**
   - Early detection of issues
   - Clear visibility into system behavior
   - Enabled data-driven decisions

### Challenges Faced

1. **Network Policies Complexity**
   - Initial policies too restrictive
   - Required multiple iterations
   - **Solution:** Start permissive, then restrict

2. **HPA Stabilization**
   - Aggressive scale-up/down caused instability
   - **Solution:** Tuned stabilization windows

3. **Secret Management**
   - Manual secret creation error-prone
   - **Solution:** Automated with scripts

4. **Certificate Renewal**
   - Let's Encrypt rate limits hit during testing
   - **Solution:** Use self-signed for dev/test

5. **Database as Single Point of Failure**
   - No replication initially
   - **Solution:** Implemented StatefulSet with replicas

### Best Practices Implemented

✅ **Infrastructure as Code:** All configurations in Git  
✅ **Immutable Deployments:** Always use image tags, never `:latest`  
✅ **Resource Limits:** Every pod has requests and limits  
✅ **Security First:** Non-root containers, read-only filesystems  
✅ **Observability:** Metrics, logs, and traces from day one  
✅ **Automation:** Scripts for common operations  
✅ **Documentation:** Comprehensive READMEs and runbooks  

---

## 🚀 Future Improvements

### Short Term (1-2 months)

1. **Service Mesh (Istio/Linkerd)**
   - Advanced traffic management
   - mTLS between services
   - Better observability

2. **GitOps (ArgoCD/Flux)**
   - Automated deployments
   - Git as source of truth
   - Rollback capabilities

3. **Secrets Management (Vault/Sealed Secrets)**
   - Encrypted secrets in Git
   - Automatic rotation
   - Audit logging

4. **Backup and DR**
   - Automated backups
   - Cross-region replication
   - Disaster recovery plan

### Medium Term (3-6 months)

1. **Multi-Cluster**
   - High availability across regions
   - Geographic load distribution
   - Improved disaster recovery

2. **Advanced Autoscaling**
   - Vertical Pod Autoscaler
   - Cluster Autoscaler
   - KEDA for event-driven scaling

3. **Service Catalog**
   - Self-service for developers
   - Standardized deployments
   - Cost tracking

4. **Chaos Engineering**
   - Chaos Mesh or Litmus
   - Automated failure injection
   - Resilience testing

### Long Term (6-12 months)

1. **Policy as Code**
   - OPA/Gatekeeper
   - Automated compliance checking
   - Security policies

2. **Machine Learning Ops**
   - Model serving infrastructure
   - A/B testing framework
   - Feature store

3. **Cost Optimization**
   - Spot instance integration
   - Resource right-sizing
   - Showback/chargeback

---

## 📖 Additional Resources

### Documentation
- [Kubernetes Official Docs](https://kubernetes.io/docs/)
- [Prometheus Docs](https://prometheus.io/docs/)
- [Grafana Docs](https://grafana.com/docs/)

### Tools
- [k9s](https://k9scli.io/) - Terminal UI for Kubernetes
- [Lens](https://k8slens.dev/) - Kubernetes IDE
- [Kustomize](https://kustomize.io/) - Configuration management
- [Helm](https://helm.sh/) - Package manager

### Learning
- [Kubernetes Patterns](https://www.oreilly.com/library/view/kubernetes-patterns/9781492050278/)
- [Production Kubernetes](https://www.oreilly.com/library/view/production-kubernetes/9781492092292/)
- [Cloud Native DevOps](https://www.oreilly.com/library/view/cloud-native-devops/9781492040750/)

---

## 👥 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

---

## 📄 License

This project is licensed under the MIT License - see LICENSE file for details.

---

## 📞 Support

- **Issues:** GitHub Issues
- **Email:** ibn3bbas.mo7ammed.elhadi@gmail.com
- **Phone:** +966534900507

---

## ✅ Checklist for Production Deployment

- [ ] Update all placeholder values (domains, emails, etc.)
- [ ] Generate strong secrets
- [ ] Configure backup strategy
- [ ] Setup monitoring alerts
- [ ] Test disaster recovery procedures
- [ ] Document runbooks
- [ ] Setup CI/CD pipeline
- [ ] Configure logging aggregation
- [ ] Implement rate limiting
- [ ] Setup WAF (Web Application Firewall)
- [ ] Configure DDoS protection
- [ ] Perform security audit
- [ ] Load testing
- [ ] Chaos engineering tests
- [ ] Cost optimization review

---

**Project Version:** 1.0.0  
**Last Updated:** 2025-12-01  
**Maintainer:** Rasid Infrastructure