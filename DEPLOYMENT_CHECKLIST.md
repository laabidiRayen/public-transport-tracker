# OpenShift Deployment Checklist
## Public Transport Tracker

## ✅ Pre-Deployment Checklist

### Environment Setup
- [ ] OpenShift CLI (oc) installed and verified
- [ ] Logged into OpenShift cluster
- [ ] GitHub repository cloned locally
- [ ] Docker Desktop running (for local builds)

### Configuration Review
- [ ] Update database credentials in secrets
- [ ] Configure custom domain names in routes
- [ ] Review resource limits and requests
- [ ] Set appropriate environment variables
- [ ] Configure storage class for PVCs

### Security Review
- [ ] Change default passwords
- [ ] Generate new SECRET_KEY
- [ ] Review RBAC permissions
- [ ] Configure network policies (if needed)
- [ ] Enable TLS/HTTPS for routes

---

## 📋 Deployment Steps

### Phase 1: Initial Setup
- [ ] Create OpenShift project/namespace
- [ ] Apply ConfigMaps
- [ ] Apply Secrets
- [ ] Create PersistentVolumeClaims

**Commands:**
```bash
oc new-project transport-tracker
oc apply -f k8s/00-namespace-config-secret.yaml
```

### Phase 2: Build Setup
- [ ] Create ImageStreams
- [ ] Create BuildConfigs
- [ ] Start backend build
- [ ] Start frontend build
- [ ] Verify builds complete successfully

**Commands:**
```bash
oc apply -f k8s/04-imagestreams.yaml
oc apply -f k8s/05-buildconfigs.yaml
oc start-build backend --follow
oc start-build frontend --follow
```

### Phase 3: Database Deployment
Choose one option:

#### Option A: PostgreSQL (Production)
- [ ] Apply PostgreSQL DeploymentConfig
- [ ] Wait for PostgreSQL pod to be ready
- [ ] Verify database connection

**Commands:**
```bash
oc apply -f k8s/03-deploymentconfigs.yaml
oc rollout status dc/postgres
```

#### Option B: SQLite (Development)
- [ ] Apply SQLite backend DeploymentConfig
- [ ] Wait for backend pod to be ready
- [ ] Verify database initialization

**Commands:**
```bash
oc apply -f k8s/06-sqlite-deployment.yaml
oc rollout status dc/backend-sqlite
```

### Phase 4: Application Deployment
- [ ] Deploy backend application
- [ ] Deploy frontend application
- [ ] Verify all pods are running
- [ ] Check pod logs for errors

**Commands:**
```bash
oc get pods
oc logs -f dc/backend
oc logs -f dc/frontend
```

### Phase 5: Networking
- [ ] Create Services
- [ ] Create Routes
- [ ] Verify internal service connectivity
- [ ] Test external route access

**Commands:**
```bash
oc apply -f k8s/01-routes.yaml
oc get routes
oc get svc
```

### Phase 6: Autoscaling (Optional)
- [ ] Apply HorizontalPodAutoscalers
- [ ] Verify HPA configuration
- [ ] Monitor scaling behavior

**Commands:**
```bash
oc apply -f k8s/02-autoscaling.yaml
oc get hpa
```

---

## ✅ Post-Deployment Verification

### Resource Verification
- [ ] All pods are in Running state
- [ ] All builds completed successfully
- [ ] All services created
- [ ] All routes accessible
- [ ] PVCs are Bound

**Commands:**
```bash
oc get all
oc get pods
oc get svc
oc get routes
oc get pvc
```

### Functionality Testing
- [ ] Backend health endpoint returns 200
- [ ] Frontend loads successfully
- [ ] API endpoints respond correctly
- [ ] Database queries work
- [ ] Can create/read/update/delete data

**Test Commands:**
```bash
# Get routes
FRONTEND_URL=$(oc get route frontend-route -o jsonpath='{.spec.host}')
BACKEND_URL=$(oc get route backend-route -o jsonpath='{.spec.host}')

# Test backend health
curl https://$BACKEND_URL/api/health

# Test routes endpoint
curl https://$BACKEND_URL/api/routes

# Test frontend
curl https://$FRONTEND_URL
```

### Performance Check
- [ ] Response times acceptable
- [ ] Resource usage within limits
- [ ] No memory leaks detected
- [ ] Logs show no critical errors

**Commands:**
```bash
oc adm top pods
oc adm top nodes
oc logs dc/backend | grep ERROR
```

### Security Verification
- [ ] HTTPS enabled on all routes
- [ ] Secrets properly configured
- [ ] Pods running as non-root
- [ ] Network policies applied (if configured)

**Commands:**
```bash
oc get routes -o yaml | grep tls
oc get secrets
oc describe pod <pod-name> | grep -i security
```

---

## 🔄 Automated Deployment

### Using PowerShell (Windows)
```powershell
# Full deployment
.\deploy-openshift.ps1

# With specific options
.\deploy-openshift.ps1 -UsePostgres -EnableAutoscaling
```

### Using Bash (Linux/Mac)
```bash
chmod +x deploy-openshift.sh
./deploy-openshift.sh
```

### Verification Script
```powershell
.\verify-deployment.ps1
```

---

## 📊 Monitoring Checklist

### Daily Checks
- [ ] All pods running
- [ ] No pod restarts
- [ ] Disk usage acceptable
- [ ] No critical errors in logs

### Weekly Checks
- [ ] Review resource usage trends
- [ ] Check for security updates
- [ ] Review application logs
- [ ] Test backup/restore procedures

### Monthly Checks
- [ ] Update dependencies
- [ ] Review and update configurations
- [ ] Performance testing
- [ ] Security audit

---

## 🚨 Troubleshooting Checklist

### Build Issues
- [ ] Check build logs: `oc logs -f bc/backend`
- [ ] Verify GitHub access
- [ ] Check Dockerfile syntax
- [ ] Verify base images available

### Deployment Issues
- [ ] Check pod status: `oc get pods`
- [ ] Check pod logs: `oc logs <pod-name>`
- [ ] Check events: `oc get events`
- [ ] Verify image pull successful
- [ ] Check resource limits

### Networking Issues
- [ ] Verify services exist: `oc get svc`
- [ ] Check service selectors match pod labels
- [ ] Test internal connectivity
- [ ] Verify routes created: `oc get routes`
- [ ] Check DNS resolution

### Database Issues
- [ ] Check database pod running
- [ ] Verify credentials correct
- [ ] Check connection from backend
- [ ] Verify PVC bound
- [ ] Check database logs

### Performance Issues
- [ ] Check resource usage: `oc adm top pods`
- [ ] Review application logs
- [ ] Check for memory leaks
- [ ] Verify autoscaling working
- [ ] Database query performance

---

## 📝 Access Information

After successful deployment, record these details:

### URLs
- **Frontend URL**: `https://__________________________`
- **Backend API URL**: `https://__________________________`
- **OpenShift Console**: `https://__________________________`

### Credentials
- **OpenShift User**: `__________________________`
- **Database User**: `__________________________`
- **Registry**: `__________________________`

### Key Commands
```bash
# Project access
oc project transport-tracker

# View all resources
oc get all

# View logs
oc logs -f dc/backend

# Scale application
oc scale dc/backend --replicas=3

# Update configuration
oc edit configmap transport-config

# Rollback deployment
oc rollout undo dc/backend
```

---

## 🎯 Success Criteria

Deployment is successful when:
- ✅ All pods are in Running state
- ✅ Health endpoint returns healthy status
- ✅ Frontend loads without errors
- ✅ API endpoints respond correctly
- ✅ Database operations work
- ✅ Routes are accessible externally
- ✅ HTTPS is enforced
- ✅ No critical errors in logs

---

## 📞 Support

If you encounter issues:
1. Check the troubleshooting section
2. Review pod logs
3. Check OpenShift events
4. Consult the deployment guide
5. Create a GitHub issue

---

**Deployment Date**: _____________
**Deployed By**: _____________
**Version**: _____________
**Environment**: _____________

---

**Checklist Completed**: ☐ Yes ☐ No
**Notes**: _______________________________________________
