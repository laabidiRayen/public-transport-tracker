# 🚀 OpenShift Deployment - Quick Start Guide

## Prerequisites
```bash
# Check if you have OpenShift CLI installed
oc version

# Login to your OpenShift cluster
oc login https://your-cluster-url

# Verify login
oc whoami
```

---

## 🎯 Deploy in 3 Steps

### Step 1: Clone Repository
```bash
git clone https://github.com/laabidiRayen/public-transport-tracker.git
cd public-transport-tracker
```

### Step 2: Run Deployment Script

**Windows (PowerShell):**
```powershell
.\deploy-openshift.ps1
```

**Linux/Mac (Bash):**
```bash
chmod +x deploy-openshift.sh
./deploy-openshift.sh
```

### Step 3: Verify Deployment
```powershell
.\verify-deployment.ps1
```

---

## 📝 Deployment Options

### Full Deployment (PostgreSQL)
```powershell
.\deploy-openshift.ps1 -UsePostgres
```

### Lightweight Deployment (SQLite)
```powershell
.\deploy-openshift.ps1
```

### Without Autoscaling
```powershell
.\deploy-openshift.ps1 -EnableAutoscaling:$false
```

### Custom Project Name
```powershell
.\deploy-openshift.ps1 -ProjectName "my-transport-app"
```

---

## 🔍 Manual Deployment (Step-by-Step)

```bash
# 1. Create project
oc new-project transport-tracker

# 2. Create resources
oc apply -f k8s/00-namespace-config-secret.yaml
oc apply -f k8s/04-imagestreams.yaml
oc apply -f k8s/05-buildconfigs.yaml

# 3. Build images
oc start-build backend --follow
oc start-build frontend --follow

# 4. Deploy (choose one)
oc apply -f k8s/03-deploymentconfigs.yaml     # PostgreSQL
# OR
oc apply -f k8s/06-sqlite-deployment.yaml     # SQLite

# 5. Create routes
oc apply -f k8s/01-routes.yaml

# 6. Enable autoscaling (optional)
oc apply -f k8s/02-autoscaling.yaml
```

---

## 📊 Check Deployment Status

```bash
# View all resources
oc get all

# Check pods
oc get pods

# Check services
oc get svc

# Check routes
oc get routes

# View logs
oc logs -f dc/backend
oc logs -f dc/frontend
```

---

## 🌐 Access Your Application

```bash
# Get URLs
echo "Frontend: https://$(oc get route frontend-route -o jsonpath='{.spec.host}')"
echo "Backend: https://$(oc get route backend-route -o jsonpath='{.spec.host}')"

# Test backend health
curl https://$(oc get route backend-route -o jsonpath='{.spec.host}')/api/health
```

---

## 🛠️ Common Operations

### Scale Application
```bash
oc scale dc/backend --replicas=3
oc scale dc/frontend --replicas=2
```

### View Logs
```bash
oc logs -f dc/backend
oc logs -f dc/frontend
oc logs --previous <pod-name>  # If crashed
```

### Update Configuration
```bash
oc edit configmap transport-config
oc rollout latest dc/backend
```

### Access Pod Shell
```bash
oc rsh dc/backend
oc rsh dc/frontend
```

### Rollback Deployment
```bash
oc rollout undo dc/backend
oc rollout history dc/backend
```

### Port Forward for Local Access
```bash
oc port-forward svc/backend-service 5000:5000
# Access at http://localhost:5000
```

---

## 🚨 Troubleshooting

### Build Failed
```bash
# Check build logs
oc logs -f bc/backend

# Restart build
oc start-build backend
```

### Pod Crashing
```bash
# Check logs
oc logs <pod-name>
oc logs --previous <pod-name>

# Describe pod
oc describe pod <pod-name>

# Check events
oc get events
```

### Can't Access Routes
```bash
# Check routes
oc get routes
oc describe route frontend-route

# Test internal service
oc run test --image=busybox -it --rm -- wget -O- http://backend-service:5000/api/health
```

---

## 🔐 Security (Production)

### Update Secrets
```bash
oc create secret generic transport-secrets \
  --from-literal=DB_PASSWORD='new-secure-password' \
  --from-literal=SECRET_KEY='new-secret-key' \
  --dry-run=client -o yaml | oc apply -f -

oc rollout latest dc/backend
```

---

## 🗑️ Cleanup

### Delete Specific Resources
```bash
oc delete dc/backend
oc delete svc/backend-service
oc delete route/backend-route
```

### Delete Everything
```bash
oc delete project transport-tracker
```

---

## 📚 Documentation

- **Complete Guide**: [docs/OPENSHIFT_DEPLOYMENT_COMPLETE.md](docs/OPENSHIFT_DEPLOYMENT_COMPLETE.md)
- **Deployment Checklist**: [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)
- **Phase 4 Summary**: [PHASE4_COMPLETION_SUMMARY.md](PHASE4_COMPLETION_SUMMARY.md)

---

## 🎯 Resource Overview

| Resource | File | Purpose |
|----------|------|---------|
| Namespace, Config, Secrets | 00-namespace-config-secret.yaml | Base configuration |
| Routes | 01-routes.yaml | External access |
| Autoscaling | 02-autoscaling.yaml | Auto-scaling rules |
| DeploymentConfigs | 03-deploymentconfigs.yaml | PostgreSQL deployment |
| ImageStreams | 04-imagestreams.yaml | Image registry |
| BuildConfigs | 05-buildconfigs.yaml | CI/CD pipeline |
| SQLite Deployment | 06-sqlite-deployment.yaml | Alternative deployment |

---

## ✅ Success Criteria

Deployment is successful when:
- ✅ All pods are Running
- ✅ Health endpoint returns 200
- ✅ Frontend loads without errors
- ✅ API responds correctly
- ✅ Routes are accessible
- ✅ HTTPS is enforced

---

## 📞 Need Help?

1. Check logs: `oc logs -f dc/backend`
2. Check events: `oc get events`
3. Review documentation
4. Run verification: `.\verify-deployment.ps1`
5. GitHub Issues: [Create Issue](https://github.com/laabidiRayen/public-transport-tracker/issues)

---

**Quick Deploy**: `.\deploy-openshift.ps1`  
**Verify**: `.\verify-deployment.ps1`  
**Clean Up**: `oc delete project transport-tracker`

---

**Version**: 1.0 | **Date**: January 5, 2026 | **Status**: ✅ Production Ready
