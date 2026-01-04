# OpenShift Deployment Guide

## Overview

This guide provides step-by-step instructions for deploying the Public Transport Tracker application to OpenShift cluster.

## Prerequisites

### Required
- OpenShift CLI (oc) installed and configured
- Access to an OpenShift cluster (4.8+)
- Docker images pushed to a registry (Docker Hub, Quay.io, ECR, etc.)
- kubectl or oc command-line tools

### Recommended
- OpenShift project admin access
- 10GB minimum storage for PersistentVolumes
- 4GB minimum memory available in cluster

## Installation Steps

### Step 1: Prepare Docker Images

#### Option A: Push to Docker Hub
```bash
# Build images
docker build -t your-username/ptt-backend:latest ./backend
docker build -t your-username/ptt-frontend:latest ./frontend
docker build -t your-username/ptt-postgres:latest ./database

# Push to Docker Hub
docker push your-username/ptt-backend:latest
docker push your-username/ptt-frontend:latest
docker push your-username/ptt-postgres:latest
```

#### Option B: Push to OpenShift Internal Registry
```bash
# Get OpenShift registry URL
REGISTRY=$(oc registry info)

# Tag images
docker tag ptt-backend:latest $REGISTRY/transport-tracker/ptt-backend:latest
docker tag ptt-frontend:latest $REGISTRY/transport-tracker/ptt-frontend:latest
docker tag ptt-postgres:latest $REGISTRY/transport-tracker/ptt-postgres:latest

# Push images
docker push $REGISTRY/transport-tracker/ptt-backend:latest
docker push $REGISTRY/transport-tracker/ptt-frontend:latest
docker push $REGISTRY/transport-tracker/ptt-postgres:latest
```

### Step 2: Login to OpenShift Cluster

```bash
# Login to OpenShift
oc login https://your-openshift-cluster:6443

# Or using token
oc login --token=your-token --server=https://your-openshift-cluster:6443
```

### Step 3: Deploy Application

#### Create namespace
```bash
oc create namespace transport-tracker
oc project transport-tracker
```

#### Update image references in manifests
Edit the manifest files to use your image registry:

**In `00-namespace-config-secret.yaml`:**
- Update image URLs for postgres, backend, frontend
- Change database password in Secret

**In `01-routes.yaml`:**
- Update host URLs (change example.com to your actual domain)

#### Apply manifests in order
```bash
# Apply namespace and configuration
oc apply -f k8s/00-namespace-config-secret.yaml

# Apply routes
oc apply -f k8s/01-routes.yaml

# Apply autoscaling
oc apply -f k8s/02-autoscaling.yaml
```

### Step 4: Verify Deployment

```bash
# Check if all pods are running
oc get pods -n transport-tracker

# Check services
oc get svc -n transport-tracker

# Check routes
oc get routes -n transport-tracker

# Check deployments
oc get deployments -n transport-tracker

# Check persistent volumes
oc get pvc -n transport-tracker
```

### Step 5: Access the Application

#### Get Frontend URL
```bash
oc get route frontend-route -n transport-tracker -o jsonpath='{.spec.host}'
```

#### Get Backend API URL
```bash
oc get route backend-route -n transport-tracker -o jsonpath='{.spec.host}'
```

#### Test API health
```bash
curl https://$(oc get route backend-route -n transport-tracker -o jsonpath='{.spec.host}')/api/health
```

## Troubleshooting

### Check Pod Logs

```bash
# View logs from a specific pod
oc logs -f pod/backend-xxxxx -n transport-tracker

# View logs from all pods in a deployment
oc logs -f deployment/backend -n transport-tracker

# View logs from database pod
oc logs -f statefulset/postgres -n transport-tracker
```

### Check Pod Events

```bash
# Describe a pod to see events
oc describe pod/backend-xxxxx -n transport-tracker

# Check pod status
oc status -n transport-tracker
```

### Common Issues

#### Pod not starting
```bash
# Check resource availability
oc describe node

# Check if storage is available
oc get pv

# View pod description for error details
oc describe pod pod-name -n transport-tracker
```

#### Database connection failed
```bash
# Check if database pod is running
oc get pods -n transport-tracker -l app=postgres

# Check database pod logs
oc logs -f statefulset/postgres -n transport-tracker

# Verify database service
oc get svc postgres-service -n transport-tracker
```

#### Route not accessible
```bash
# Check routes
oc get routes -n transport-tracker

# Check if frontend service exists
oc get svc frontend-service -n transport-tracker

# Describe route
oc describe route frontend-route -n transport-tracker
```

## Scaling

### Manual Scaling

```bash
# Scale backend to 3 replicas
oc scale deployment backend --replicas=3 -n transport-tracker

# Scale frontend to 2 replicas
oc scale deployment frontend --replicas=2 -n transport-tracker
```

### Auto-Scaling

The deployment includes HorizontalPodAutoscalers configured to:
- Scale based on CPU and Memory utilization
- Backend: 2-5 replicas (70% CPU, 80% Memory)
- Frontend: 2-4 replicas (75% CPU, 85% Memory)

Monitor auto-scaling:
```bash
# View HPA status
oc get hpa -n transport-tracker

# Detailed HPA info
oc describe hpa backend-hpa -n transport-tracker
```

## Configuration Management

### Update ConfigMap

```bash
# Edit ConfigMap
oc edit configmap transport-config -n transport-tracker

# Or patch specific value
oc patch configmap transport-config -n transport-tracker -p '{"data":{"LOG_LEVEL":"DEBUG"}}'
```

### Update Secrets

```bash
# Edit Secret (encoded)
oc edit secret transport-secrets -n transport-tracker

# Create new secret with updated values
oc delete secret transport-secrets -n transport-tracker
oc create secret generic transport-secrets \
  --from-literal=DB_USER=postgres \
  --from-literal=DB_PASSWORD=your-new-password \
  --from-literal=SECRET_KEY=your-secret-key \
  -n transport-tracker
```

## Backup and Restore

### Backup Database

```bash
# Get database pod name
DB_POD=$(oc get pod -n transport-tracker -l app=postgres -o jsonpath='{.items[0].metadata.name}')

# Create backup
oc exec $DB_POD -n transport-tracker -- pg_dump -U postgres transport_db > backup.sql
```

### Restore Database

```bash
# Get database pod name
DB_POD=$(oc get pod -n transport-tracker -l app=postgres -o jsonpath='{.items[0].metadata.name}')

# Restore from backup
oc exec -i $DB_POD -n transport-tracker -- psql -U postgres transport_db < backup.sql
```

## Monitoring

### Check Resource Usage

```bash
# Pod resource usage
oc top pods -n transport-tracker

# Node resource usage
oc top nodes
```

### View Events

```bash
# Project events
oc get events -n transport-tracker

# Sort by timestamp
oc get events -n transport-tracker --sort-by='.lastTimestamp'
```

## Cleanup

### Delete entire deployment

```bash
# Delete all resources in namespace
oc delete namespace transport-tracker

# Or delete specific manifests
oc delete -f k8s/02-autoscaling.yaml
oc delete -f k8s/01-routes.yaml
oc delete -f k8s/00-namespace-config-secret.yaml
```

## Advanced Configuration

### Resource Quotas

Create resource quotas to limit namespace usage:

```bash
oc create resourcequota compute-quota \
  --hard=requests.cpu=2,requests.memory=4Gi,limits.cpu=4,limits.memory=8Gi \
  -n transport-tracker
```

### Network Policies

Restrict network traffic between pods:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-network-policy
  namespace: transport-tracker
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
```

### Security Context

Enforce pod security policies (update manifests):

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 2000
  capabilities:
    drop:
    - ALL
```

## Useful OpenShift Commands

```bash
# Switch project
oc project transport-tracker

# Get cluster info
oc cluster-info

# Get API resources
oc api-resources

# Get resource definitions
oc explain deployment

# Stream logs in real-time
oc logs -f deployment/backend

# Port forward to local machine
oc port-forward svc/backend-service 5000:5000

# Execute command in pod
oc exec -it pod/backend-xxxxx -- bash

# Copy files from pod
oc cp transport-tracker/postgres-xxxxx:/var/lib/postgresql/data/backup.sql ./backup.sql

# View deployment rollout history
oc rollout history deployment/backend

# Rollback to previous version
oc rollout undo deployment/backend
```

## Performance Tuning

### Database Connection Pooling
Configure in backend deployment:
```bash
oc set env deployment/backend \
  DB_POOL_SIZE=20 \
  DB_MAX_OVERFLOW=40 \
  -n transport-tracker
```

### Nginx Worker Processes
Update frontend image with optimized configuration

### Resource Requests/Limits
Adjust based on monitoring data:
```bash
oc set resources deployment/backend \
  --requests=cpu=500m,memory=512Mi \
  --limits=cpu=1000m,memory=1Gi \
  -n transport-tracker
```

## Next Steps

1. **Monitoring**: Set up Prometheus and Grafana
2. **Logging**: Configure centralized logging (ELK/Loki)
3. **CI/CD**: Implement automated deployment pipeline
4. **Backups**: Schedule regular database backups
5. **Security**: Implement RBAC and network policies
6. **Documentation**: Create runbooks for operations team

## Support Resources

- OpenShift Documentation: https://docs.openshift.com
- Kubernetes Documentation: https://kubernetes.io/docs
- PostgreSQL Docker: https://hub.docker.com/_/postgres
- Flask Documentation: https://flask.palletsprojects.com
