#!/bin/bash
# OpenShift Deployment Script for Public Transport Tracker
# This script deploys the application to an OpenShift cluster

set -e

# Configuration
PROJECT_NAME="transport-tracker"
GITHUB_REPO="https://github.com/laabidiRayen/public-transport-tracker.git"
REGISTRY="image-registry.openshift-image-registry.svc:5000"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  OpenShift Deployment Script${NC}"
echo -e "${CYAN}========================================${NC}\n"

# Check if logged into OpenShift
echo -e "${YELLOW}Checking OpenShift login...${NC}"
if ! oc whoami &> /dev/null; then
    echo -e "${RED}Error: Not logged into OpenShift cluster${NC}"
    echo -e "${YELLOW}Please run: oc login <your-cluster-url>${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Logged in as: $(oc whoami)${NC}\n"

# Step 1: Create/Switch to project
echo -e "${YELLOW}Step 1: Creating OpenShift project...${NC}"
if oc get project $PROJECT_NAME &> /dev/null; then
    echo -e "${GREEN}✓ Project '$PROJECT_NAME' already exists${NC}"
    oc project $PROJECT_NAME
else
    oc new-project $PROJECT_NAME --display-name="Public Transport Tracker" --description="Real-time public transport tracking application"
    echo -e "${GREEN}✓ Project '$PROJECT_NAME' created${NC}"
fi
echo ""

# Step 2: Apply namespace, config, and secrets
echo -e "${YELLOW}Step 2: Creating ConfigMaps and Secrets...${NC}"
oc apply -f k8s/00-namespace-config-secret.yaml
echo -e "${GREEN}✓ ConfigMaps and Secrets created${NC}\n"

# Step 3: Create ImageStreams
echo -e "${YELLOW}Step 3: Creating ImageStreams...${NC}"
oc apply -f k8s/04-imagestreams.yaml
echo -e "${GREEN}✓ ImageStreams created${NC}\n"

# Step 4: Create BuildConfigs
echo -e "${YELLOW}Step 4: Creating BuildConfigs...${NC}"
oc apply -f k8s/05-buildconfigs.yaml
echo -e "${GREEN}✓ BuildConfigs created${NC}\n"

# Step 5: Start builds
echo -e "${YELLOW}Step 5: Starting image builds...${NC}"
echo -e "${CYAN}Building backend image...${NC}"
oc start-build backend --follow
echo -e "${GREEN}✓ Backend image built${NC}\n"

echo -e "${CYAN}Building frontend image...${NC}"
oc start-build frontend --follow
echo -e "${GREEN}✓ Frontend image built${NC}\n"

# Step 6: Deploy PostgreSQL (comment out if using SQLite)
echo -e "${YELLOW}Step 6: Deploying database...${NC}"
read -p "Deploy PostgreSQL? (y/n, default: y): " deploy_postgres
deploy_postgres=${deploy_postgres:-y}

if [[ $deploy_postgres == "y" ]]; then
    oc apply -f k8s/03-deploymentconfigs.yaml
    echo -e "${GREEN}✓ PostgreSQL deployment created${NC}"
else
    echo -e "${CYAN}Deploying SQLite backend instead...${NC}"
    oc apply -f k8s/06-sqlite-deployment.yaml
    echo -e "${GREEN}✓ SQLite backend deployment created${NC}"
fi
echo ""

# Step 7: Create Routes
echo -e "${YELLOW}Step 7: Creating Routes...${NC}"
oc apply -f k8s/01-routes.yaml
echo -e "${GREEN}✓ Routes created${NC}\n"

# Step 8: Create Autoscaling (optional)
echo -e "${YELLOW}Step 8: Setting up autoscaling...${NC}"
read -p "Enable autoscaling? (y/n, default: y): " enable_hpa
enable_hpa=${enable_hpa:-y}

if [[ $enable_hpa == "y" ]]; then
    oc apply -f k8s/02-autoscaling.yaml
    echo -e "${GREEN}✓ Autoscaling configured${NC}"
else
    echo -e "${CYAN}Skipping autoscaling${NC}"
fi
echo ""

# Step 9: Wait for deployments
echo -e "${YELLOW}Step 9: Waiting for deployments to complete...${NC}"
echo -e "${CYAN}This may take a few minutes...${NC}\n"

# Wait for rollout
oc rollout status dc/backend --watch=true || oc rollout status dc/backend-sqlite --watch=true
oc rollout status dc/frontend --watch=true

echo -e "\n${GREEN}✓ All deployments completed${NC}\n"

# Step 10: Get Routes and display info
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Deployment Complete!${NC}"
echo -e "${CYAN}========================================${NC}\n"

echo -e "${GREEN}Access URLs:${NC}"
FRONTEND_URL=$(oc get route frontend-route -o jsonpath='{.spec.host}' 2>/dev/null || echo "Not found")
BACKEND_URL=$(oc get route backend-route -o jsonpath='{.spec.host}' 2>/dev/null || echo "Not found")

echo -e "${YELLOW}Frontend:${NC} https://$FRONTEND_URL"
echo -e "${YELLOW}Backend API:${NC} https://$BACKEND_URL"

echo -e "\n${GREEN}Useful commands:${NC}"
echo -e "  View pods:       ${CYAN}oc get pods${NC}"
echo -e "  View services:   ${CYAN}oc get svc${NC}"
echo -e "  View routes:     ${CYAN}oc get routes${NC}"
echo -e "  View logs:       ${CYAN}oc logs -f <pod-name>${NC}"
echo -e "  Scale app:       ${CYAN}oc scale dc/backend --replicas=3${NC}"
echo -e "  Delete all:      ${CYAN}oc delete project $PROJECT_NAME${NC}"

echo -e "\n${CYAN}========================================${NC}\n"
