# Public Transport Tracker

A multi-container microservices application for tracking bus and train schedules, viewing real-time delays, and managing transport information efficiently. This application is optimized for deployment on OpenShift.

## 📋 Overview

Public Transport Tracker is composed of three main services:
- **Frontend**: HTML/CSS/JavaScript web interface (Nginx)
- **Backend API**: Flask Python REST API
- **Database**: PostgreSQL for data persistence

## 🚀 Quick Start

### Prerequisites

Choose one of the following setup methods:

#### For Local Development (Docker)
- Docker Desktop installed and running
- Git installed

#### For OpenShift Deployment
- OpenShift CLI (`oc`) installed
- Access to an OpenShift cluster (4.8+)
- Docker installed (for building and pushing images)

---

## 🏃 Local Development Setup (5 minutes)

### 1. Clone the Repository
```bash
git clone https://github.com/YOUR_USERNAME/public-transport-tracker.git
cd "public-transport-tracker"
```

### 2. Start Services with Docker Compose
```bash
docker-compose -f k8s/docker-compose.yaml up -d
```

### 3. Verify Services are Running
```bash
docker-compose -f k8s/docker-compose.yaml ps
```

### 4. Access the Application
- **Frontend**: http://localhost
- **API Documentation**: http://localhost:5000/api
- **API Health Check**: http://localhost:5000/api/health

### 5. Test API Endpoints
```bash
# Get all routes
curl http://localhost:5000/api/routes

# Get schedules
curl http://localhost:5000/api/schedules

# Get delays
curl http://localhost:5000/api/delays
```

### 6. Stop Services
```bash
docker-compose -f k8s/docker-compose.yaml down
```

---

## ☸️ OpenShift Deployment (30 minutes)

### 1. Prerequisites

Ensure you have:
- OpenShift CLI (`oc`) installed
- Access to an OpenShift cluster
- Docker installed locally
- A container registry account (Docker Hub, Quay.io, ECR, etc.)

### 2. Login to OpenShift Cluster

```bash
oc login https://your-openshift-cluster:6443
```

Or using a token:
```bash
oc login --token=your-token --server=https://your-openshift-cluster:6443
```

### 3. Build and Push Docker Images

#### Option A: Push to Docker Hub
```bash
# Build images
docker build -t your-username/ptt-backend:latest ./backend
docker build -t your-username/ptt-frontend:latest ./frontend
docker build -t your-username/ptt-postgres:latest ./database

# Log in to Docker Hub
docker login

# Push images
docker push your-username/ptt-backend:latest
docker push your-username/ptt-frontend:latest
docker push your-username/ptt-postgres:latest
```

#### Option B: Use OpenShift Internal Registry
```bash
# Get OpenShift registry URL
REGISTRY=$(oc registry info)

# Build and tag images
docker build -t $REGISTRY/transport-tracker/ptt-backend:latest ./backend
docker build -t $REGISTRY/transport-tracker/ptt-frontend:latest ./frontend
docker build -t $REGISTRY/transport-tracker/ptt-postgres:latest ./database

# Log in to OpenShift registry
oc registry login

# Push images
docker push $REGISTRY/transport-tracker/ptt-backend:latest
docker push $REGISTRY/transport-tracker/ptt-frontend:latest
docker push $REGISTRY/transport-tracker/ptt-postgres:latest
```

### 4. Create Project Namespace

```bash
# Create namespace
oc create namespace transport-tracker

# Switch to the namespace
oc project transport-tracker
```

### 5. Update Configuration Files

Edit the manifest files in the `k8s/` directory with your specific values:

**`k8s/00-namespace-config-secret.yaml`:**
- Update image registry URLs to match your pushed images
- Change database password in the Secret section
- Update any environment variables

Example:
```yaml
- Replace: `docker.io/your-username/ptt-backend`
- Replace: `docker.io/your-username/ptt-frontend`
- Replace: `docker.io/your-username/ptt-postgres`
- Set a secure database password
```

**`k8s/01-routes.yaml`:**
- Update the `host` field to use your actual domain
- Change from `example.com` to your domain name

### 6. Deploy Application Manifests

Apply the Kubernetes/OpenShift manifests in order:

```bash
# Create namespace, config maps, and secrets
oc apply -f k8s/00-namespace-config-secret.yaml

# Create image streams
oc apply -f k8s/04-imagestreams.yaml

# Create database deployment
oc apply -f k8s/06-sqlite-deployment.yaml

# Create build configs
oc apply -f k8s/05-buildconfigs.yaml

# Create deployment configs
oc apply -f k8s/03-deploymentconfigs.yaml

# Create routes for external access
oc apply -f k8s/01-routes.yaml

# Configure autoscaling
oc apply -f k8s/02-autoscaling.yaml
```

### 7. Verify Deployment

Check if all pods are running:
```bash
# List all pods
oc get pods -n transport-tracker

# Wait for all pods to be in Running state
oc get pods -n transport-tracker -w

# View deployment status
oc status -n transport-tracker
```

### 8. Access the Application

Get the route URLs:
```bash
oc get routes -n transport-tracker
```

You'll see output like:
```
NAME       HOST/PORT                    PATH   SERVICES      PORT   TERMINATION
frontend   frontend.example.com                frontend      80
backend    backend.example.com                backend        5000
```

### 9. Check Logs

Monitor application logs:
```bash
# Backend API logs
oc logs -f deployment/backend -n transport-tracker

# Frontend logs
oc logs -f deployment/frontend -n transport-tracker

# Database logs
oc logs -f deployment/postgres -n transport-tracker
```

### 10. Test the Deployed Application

```bash
# Get backend route
BACKEND_URL=$(oc get route backend -n transport-tracker -o jsonpath='{.spec.host}')

# Test API
curl http://$BACKEND_URL/api/health
curl http://$BACKEND_URL/api/routes
curl http://$BACKEND_URL/api/schedules
```

---

## 📚 Additional Documentation

- [Architecture Design](ARCHITECTURE.md) - System architecture and component interactions
- [Data Model](DATA_MODEL.md) - Database schema and relationships
- [API Specification](API_SPECIFICATION.md) - REST API endpoints and usage
- [OpenShift Deployment Guide](docs/OPENSHIFT_DEPLOYMENT_GUIDE.md) - Detailed deployment instructions
- [Quick Start Guide](QUICKSTART.md) - Quick reference for setup

---

## 🐛 Troubleshooting

### Pods Not Running
```bash
# Check pod status and events
oc describe pod <pod-name> -n transport-tracker

# View pod logs
oc logs <pod-name> -n transport-tracker
```

### Image Pull Errors
```bash
# Verify image URL is correct in manifests
# Check registry credentials if using private registry
oc secrets link default <registry-secret> -n transport-tracker
```

### Database Connection Issues
```bash
# Check if database pod is running
oc get pods -l app=postgres -n transport-tracker

# Test database connectivity from backend pod
oc exec -it <backend-pod> -- python -c "import psycopg2; print('DB OK')"
```

### Routes Not Accessible
```bash
# Verify routes are created
oc get routes -n transport-tracker

# Check route configuration
oc describe route frontend -n transport-tracker
```

---

## 🔧 Advanced Operations

### Scale Deployments
```bash
# Scale backend replicas
oc scale deployment backend --replicas=3 -n transport-tracker

# Check autoscaling status
oc get hpa -n transport-tracker
```

### Redeploy Application
```bash
# Delete and reapply manifests
oc delete -f k8s/ -n transport-tracker
oc apply -f k8s/ -n transport-tracker
```

### Clean Up Everything
```bash
# Delete entire namespace (warning: irreversible)
oc delete namespace transport-tracker
```

---

## 📝 Configuration

Key configuration variables can be found in:
- `backend/config.py` - Backend Flask configuration
- `k8s/00-namespace-config-secret.yaml` - OpenShift environment variables
- `.env` files - Local development environment

---

## 🛠️ Development Workflow

1. Make code changes locally
2. Test with Docker Compose (`docker-compose up`)
3. Build new images with updated code
4. Push images to registry
5. Update image tags in manifest files
6. Redeploy to OpenShift (`oc apply`)

---

## 📄 License

This project is open source and available under the MIT License.

---

## 🤝 Support

For issues or questions:
1. Check the [OpenShift Deployment Guide](docs/OPENSHIFT_DEPLOYMENT_GUIDE.md)
2. Review [API Specification](API_SPECIFICATION.md)
3. Consult [Architecture Documentation](ARCHITECTURE.md)

To learn more about OpenShift, visit [docs.openshift.com](https://docs.openshift.com)
