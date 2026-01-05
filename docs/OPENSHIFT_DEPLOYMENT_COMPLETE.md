# OpenShift Deployment Guide
## Public Transport Tracker - Complete Deployment Instructions

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Architecture Overview](#architecture-overview)
3. [Deployment Steps](#deployment-steps)
4. [Configuration](#configuration)
5. [Monitoring and Management](#monitoring-and-management)
6. [Troubleshooting](#troubleshooting)
7. [Production Considerations](#production-considerations)

---

## Prerequisites

### Required Tools
- **OpenShift CLI (oc)**: Version 4.x or higher
  ```bash
  # Download from: https://mirror.openshift.com/pub/openshift-v4/clients/ocp/
  # Verify installation
  oc version
  ```

- **Git**: For source code management
  ```bash
  git --version
  ```

- **Docker** (optional): For local testing
  ```bash
  docker --version
  ```

### Access Requirements
- OpenShift cluster access (Developer or Admin role)
- GitHub repository access
- Registry credentials (if using external registry)

---

## Architecture Overview

### Components

```
┌─────────────────────────────────────────────────────────┐
│                    OpenShift Cluster                     │
│                                                          │
│  ┌──────────────┐     ┌──────────────┐     ┌─────────┐ │
│  │   Frontend   │────▶│   Backend    │────▶│Database │ │
│  │   (Nginx)    │     │   (Flask)    │     │(Postgres│ │
│  │   Port 80    │     │   Port 5000  │     │or SQLite│ │
│  └──────────────┘     └──────────────┘     └─────────┘ │
│         │                     │                         │
│  ┌──────────────┐     ┌──────────────┐                 │
│  │   Route      │     │   Route      │                 │
│  │  (Frontend)  │     │  (Backend)   │                 │
│  └──────────────┘     └──────────────┘                 │
│         │                     │                         │
└─────────┼─────────────────────┼─────────────────────────┘
          │                     │
          ▼                     ▼
    Internet Access       API Access
```

### Resources Created

| Resource Type | Name | Purpose |
|---------------|------|---------|
| Namespace | transport-tracker | Project isolation |
| ConfigMap | transport-config | Application configuration |
| Secret | transport-secrets | Sensitive credentials |
| PVC | postgres-pvc | PostgreSQL data storage |
| PVC | sqlite-pvc | SQLite data storage |
| ImageStream | backend | Backend image registry |
| ImageStream | frontend | Frontend image registry |
| BuildConfig | backend | Backend build pipeline |
| BuildConfig | frontend | Frontend build pipeline |
| DeploymentConfig | postgres | PostgreSQL deployment |
| DeploymentConfig | backend | Backend API deployment |
| DeploymentConfig | frontend | Frontend deployment |
| Service | postgres-service | Database internal access |
| Service | backend-service | Backend internal access |
| Service | frontend-service | Frontend internal access |
| Route | frontend-route | External frontend access |
| Route | backend-route | External API access |
| HPA | backend-hpa | Backend autoscaling |
| HPA | frontend-hpa | Frontend autoscaling |

---

## Deployment Steps

### Step 1: Login to OpenShift

```bash
# Login to your OpenShift cluster
oc login <your-cluster-api-url>

# Or with token
oc login --token=<your-token> --server=<your-cluster-api-url>

# Verify login
oc whoami
oc cluster-info
```

### Step 2: Clone Repository

```bash
git clone https://github.com/laabidiRayen/public-transport-tracker.git
cd public-transport-tracker
```

### Step 3: Automatic Deployment (Recommended)

#### Option A: Using PowerShell (Windows)

```powershell
# Deploy with SQLite (recommended for development)
.\deploy-openshift.ps1

# Deploy with PostgreSQL
.\deploy-openshift.ps1 -UsePostgres

# Deploy without autoscaling
.\deploy-openshift.ps1 -EnableAutoscaling:$false

# Custom project name
.\deploy-openshift.ps1 -ProjectName "my-transport-app"
```

#### Option B: Using Bash (Linux/Mac)

```bash
# Make script executable
chmod +x deploy-openshift.sh

# Deploy with interactive prompts
./deploy-openshift.sh

# Or edit the script to set defaults
```

### Step 4: Manual Deployment

If you prefer manual deployment or need more control:

#### 4.1 Create Project
```bash
oc new-project transport-tracker \
  --display-name="Public Transport Tracker" \
  --description="Real-time public transport tracking application"
```

#### 4.2 Create Resources (in order)
```bash
# 1. ConfigMaps, Secrets, and Services
oc apply -f k8s/00-namespace-config-secret.yaml

# 2. ImageStreams
oc apply -f k8s/04-imagestreams.yaml

# 3. BuildConfigs
oc apply -f k8s/05-buildconfigs.yaml

# 4. Start builds
oc start-build backend --follow
oc start-build frontend --follow

# 5. DeploymentConfigs (choose one database option)

# Option A: PostgreSQL (production)
oc apply -f k8s/03-deploymentconfigs.yaml

# Option B: SQLite (development/testing)
oc apply -f k8s/06-sqlite-deployment.yaml

# 6. Routes
oc apply -f k8s/01-routes.yaml

# 7. Autoscaling (optional)
oc apply -f k8s/02-autoscaling.yaml
```

#### 4.3 Verify Deployment
```bash
# Check all resources
oc get all

# Check pods status
oc get pods

# Check routes
oc get routes

# Check build status
oc get builds

# Watch deployment progress
oc rollout status dc/backend
oc rollout status dc/frontend
```

---

## Configuration

### Update ConfigMap

Edit `k8s/00-namespace-config-secret.yaml`:

```yaml
data:
  DB_HOST: "postgres-service"
  DB_PORT: "5432"
  DB_NAME: "transport_db"
  FLASK_ENV: "production"
  LOG_LEVEL: "INFO"
```

Apply changes:
```bash
oc apply -f k8s/00-namespace-config-secret.yaml
oc rollout latest dc/backend
```

### Update Secrets

**Important**: Change default passwords before production deployment!

```bash
# Update database password
oc create secret generic transport-secrets \
  --from-literal=DB_USER=postgres \
  --from-literal=DB_PASSWORD='<your-secure-password>' \
  --from-literal=SECRET_KEY='<your-secret-key>' \
  --dry-run=client -o yaml | oc apply -f -

# Restart pods to pick up new secrets
oc rollout latest dc/backend
```

### Update Routes

Edit `k8s/01-routes.yaml` to set your custom domains:

```yaml
spec:
  host: transport-tracker-frontend.apps.your-domain.com
```

Apply:
```bash
oc apply -f k8s/01-routes.yaml
```

### Environment Variables

Add custom environment variables:

```bash
oc set env dc/backend NEW_VAR=value
oc set env dc/frontend API_URL=https://api.example.com
```

---

## Monitoring and Management

### View Logs

```bash
# Backend logs
oc logs -f dc/backend

# Frontend logs
oc logs -f dc/frontend

# Postgres logs
oc logs -f dc/postgres

# Specific pod
oc logs -f <pod-name>

# Previous pod logs (if crashed)
oc logs --previous <pod-name>
```

### Scale Applications

```bash
# Manual scaling
oc scale dc/backend --replicas=3
oc scale dc/frontend --replicas=2

# Check current replicas
oc get dc
```

### Access Pod Shell

```bash
# Backend pod
oc rsh dc/backend

# Frontend pod
oc rsh dc/frontend

# Database pod
oc rsh dc/postgres

# Run command in pod
oc exec dc/backend -- env
```

### Check Resource Usage

```bash
# Pod resources
oc adm top pods

# Node resources
oc adm top nodes

# Describe pod
oc describe pod <pod-name>
```

### Database Access

#### PostgreSQL:
```bash
# Access PostgreSQL shell
oc rsh dc/postgres
psql -U postgres -d transport_db

# Run SQL command directly
oc exec dc/postgres -- psql -U postgres -d transport_db -c "SELECT * FROM routes;"

# Backup database
oc exec dc/postgres -- pg_dump -U postgres transport_db > backup.sql
```

#### SQLite:
```bash
# Access backend pod
oc rsh dc/backend-sqlite

# Access SQLite
sqlite3 /app/database/transport_db.sqlite
.tables
SELECT * FROM routes;
.quit
```

### View Events

```bash
# All events
oc get events

# Watch events
oc get events --watch

# Events for specific resource
oc describe dc/backend
```

---

## Troubleshooting

### Common Issues

#### 1. Build Failures

```bash
# Check build logs
oc logs -f bc/backend

# Restart build
oc start-build backend

# Cancel build
oc cancel-build backend-1
```

#### 2. Pod CrashLoopBackOff

```bash
# Check pod logs
oc logs <pod-name>
oc logs --previous <pod-name>

# Check events
oc describe pod <pod-name>

# Check resources
oc describe dc/backend
```

#### 3. Image Pull Errors

```bash
# Check image stream
oc describe is/backend

# Check image availability
oc get is

# Force image update
oc import-image backend --all
```

#### 4. Route Not Working

```bash
# Check route
oc get routes
oc describe route frontend-route

# Test internal service
oc run test --image=busybox -it --rm -- wget -O- http://backend-service:5000/api/health
```

#### 5. Database Connection Issues

```bash
# Check database pod
oc get pods | grep postgres
oc logs dc/postgres

# Test database connection
oc rsh dc/backend
curl http://postgres-service:5432
```

### Debug Commands

```bash
# Port forwarding for local access
oc port-forward svc/backend-service 5000:5000
# Access at http://localhost:5000

# Get detailed pod information
oc get pod <pod-name> -o yaml

# Check resource quotas
oc describe quota

# Check limits
oc describe limits
```

---

## Production Considerations

### Security

1. **Change default passwords**:
   ```bash
   oc create secret generic transport-secrets \
     --from-literal=DB_PASSWORD="$(openssl rand -base64 32)"
   ```

2. **Use TLS certificates**:
   - Configure routes with custom certificates
   - Enable HTTPS only

3. **Network policies**:
   ```bash
   oc apply -f k8s/network-policies.yaml
   ```

4. **Service accounts**:
   ```bash
   oc create serviceaccount transport-sa
   oc adm policy add-scc-to-user restricted -z transport-sa
   ```

### Performance

1. **Resource limits**:
   - Set appropriate CPU and memory limits
   - Monitor resource usage
   - Adjust based on load

2. **Autoscaling**:
   - Configure HPA thresholds
   - Set min/max replicas appropriately
   - Monitor scaling events

3. **Database tuning**:
   - Adjust PostgreSQL configuration
   - Increase connection pool
   - Add read replicas if needed

### High Availability

1. **Multiple replicas**:
   ```bash
   oc scale dc/backend --replicas=3
   oc scale dc/frontend --replicas=2
   ```

2. **Pod disruption budgets**:
   ```yaml
   apiVersion: policy/v1
   kind: PodDisruptionBudget
   metadata:
     name: backend-pdb
   spec:
     minAvailable: 1
     selector:
       matchLabels:
         app: backend
   ```

3. **Health checks**:
   - Ensure liveness and readiness probes are configured
   - Monitor probe failures

### Backup and Recovery

1. **Database backups**:
   ```bash
   # Create backup job
   oc create job backup-$(date +%Y%m%d) --from=cronjob/database-backup
   ```

2. **Configuration backups**:
   ```bash
   # Export all resources
   oc get all -o yaml > backup-all.yaml
   oc get configmaps,secrets -o yaml > backup-config.yaml
   ```

3. **Persistent volume snapshots**:
   ```bash
   oc create volumesnapshot postgres-snapshot \
     --volumesnapshotclass=<snapshot-class> \
     --source=postgres-pvc
   ```

### Monitoring

1. **Setup Prometheus metrics**
2. **Configure alerts**
3. **Use OpenShift monitoring dashboard**
4. **Application performance monitoring (APM)**

---

## Quick Reference

### Essential Commands

```bash
# Project management
oc projects                    # List projects
oc project transport-tracker   # Switch project
oc status                      # Project status

# Resource management
oc get all                     # All resources
oc get pods                    # Pods
oc get svc                     # Services
oc get routes                  # Routes
oc get dc                      # DeploymentConfigs

# Deployment
oc rollout latest dc/backend   # Trigger rollout
oc rollout status dc/backend   # Check status
oc rollout undo dc/backend     # Rollback
oc rollout history dc/backend  # View history

# Cleanup
oc delete all -l app=backend   # Delete by label
oc delete project transport-tracker  # Delete project
```

### URLs

After deployment, access your application at:
- **Frontend**: `https://<frontend-route-host>`
- **Backend API**: `https://<backend-route-host>/api`
- **Health Check**: `https://<backend-route-host>/api/health`

Get URLs:
```bash
echo "Frontend: https://$(oc get route frontend-route -o jsonpath='{.spec.host}')"
echo "Backend: https://$(oc get route backend-route -o jsonpath='{.spec.host}')"
```

---

## Support

For issues or questions:
- Check logs: `oc logs -f dc/backend`
- View events: `oc get events`
- Check documentation: [OpenShift Documentation](https://docs.openshift.com/)
- GitHub Issues: [Repository Issues](https://github.com/laabidiRayen/public-transport-tracker/issues)

---

**Last Updated**: January 5, 2026
**Version**: 1.0
