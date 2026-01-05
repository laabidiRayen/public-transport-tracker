# OpenShift Deployment Script for Windows (PowerShell)
# Public Transport Tracker - OpenShift Deployment

param(
    [string]$ProjectName = "transport-tracker",
    [string]$GitHubRepo = "https://github.com/laabidiRayen/public-transport-tracker.git",
    [switch]$UsePostgres = $false,
    [switch]$EnableAutoscaling = $true
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  OpenShift Deployment Script" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Check if oc CLI is available
Write-Host "Checking OpenShift CLI..." -ForegroundColor Yellow
try {
    $null = oc version 2>&1
    Write-Host "✓ OpenShift CLI found" -ForegroundColor Green
} catch {
    Write-Host "✗ Error: OpenShift CLI (oc) not found" -ForegroundColor Red
    Write-Host "Please install from: https://docs.openshift.com/container-platform/latest/cli_reference/openshift_cli/getting-started-cli.html" -ForegroundColor Yellow
    exit 1
}

# Check if logged into OpenShift
Write-Host "`nChecking OpenShift login..." -ForegroundColor Yellow
try {
    $user = oc whoami 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Logged in as: $user" -ForegroundColor Green
    } else {
        throw "Not logged in"
    }
} catch {
    Write-Host "✗ Error: Not logged into OpenShift cluster" -ForegroundColor Red
    Write-Host "Please run: oc login <your-cluster-url>" -ForegroundColor Yellow
    exit 1
}

# Step 1: Create/Switch to project
Write-Host "`nStep 1: Creating OpenShift project..." -ForegroundColor Yellow
$projectExists = oc get project $ProjectName 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Project '$ProjectName' already exists" -ForegroundColor Green
    oc project $ProjectName | Out-Null
} else {
    oc new-project $ProjectName --display-name="Public Transport Tracker" --description="Real-time public transport tracking application" | Out-Null
    Write-Host "✓ Project '$ProjectName' created" -ForegroundColor Green
}

# Step 2: Apply namespace, config, and secrets
Write-Host "`nStep 2: Creating ConfigMaps and Secrets..." -ForegroundColor Yellow
oc apply -f k8s/00-namespace-config-secret.yaml
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ ConfigMaps and Secrets created" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to create ConfigMaps and Secrets" -ForegroundColor Red
}

# Step 3: Create ImageStreams
Write-Host "`nStep 3: Creating ImageStreams..." -ForegroundColor Yellow
oc apply -f k8s/04-imagestreams.yaml
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ ImageStreams created" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to create ImageStreams" -ForegroundColor Red
}

# Step 4: Create BuildConfigs
Write-Host "`nStep 4: Creating BuildConfigs..." -ForegroundColor Yellow
oc apply -f k8s/05-buildconfigs.yaml
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ BuildConfigs created" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to create BuildConfigs" -ForegroundColor Red
}

# Step 5: Start builds
Write-Host "`nStep 5: Starting image builds..." -ForegroundColor Yellow
Write-Host "Building backend image..." -ForegroundColor Cyan
oc start-build backend --follow
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Backend image built successfully" -ForegroundColor Green
}

Write-Host "`nBuilding frontend image..." -ForegroundColor Cyan
oc start-build frontend --follow
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Frontend image built successfully" -ForegroundColor Green
}

# Step 6: Deploy database
Write-Host "`nStep 6: Deploying application..." -ForegroundColor Yellow
if ($UsePostgres) {
    Write-Host "Deploying with PostgreSQL..." -ForegroundColor Cyan
    oc apply -f k8s/03-deploymentconfigs.yaml
    Write-Host "✓ PostgreSQL deployment created" -ForegroundColor Green
} else {
    Write-Host "Deploying with SQLite backend..." -ForegroundColor Cyan
    oc apply -f k8s/06-sqlite-deployment.yaml
    Write-Host "✓ SQLite backend deployment created" -ForegroundColor Green
}

# Step 7: Create Routes
Write-Host "`nStep 7: Creating Routes..." -ForegroundColor Yellow
oc apply -f k8s/01-routes.yaml
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Routes created" -ForegroundColor Green
}

# Step 8: Create Autoscaling
if ($EnableAutoscaling) {
    Write-Host "`nStep 8: Setting up autoscaling..." -ForegroundColor Yellow
    oc apply -f k8s/02-autoscaling.yaml
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Autoscaling configured" -ForegroundColor Green
    }
}

# Step 9: Wait for deployments
Write-Host "`nStep 9: Waiting for deployments to complete..." -ForegroundColor Yellow
Write-Host "This may take a few minutes...`n" -ForegroundColor Cyan

if ($UsePostgres) {
    Write-Host "Waiting for backend deployment..." -ForegroundColor Cyan
    oc rollout status dc/backend --watch=true
} else {
    Write-Host "Waiting for backend-sqlite deployment..." -ForegroundColor Cyan
    oc rollout status dc/backend-sqlite --watch=true
}

Write-Host "Waiting for frontend deployment..." -ForegroundColor Cyan
oc rollout status dc/frontend --watch=true

Write-Host "`n✓ All deployments completed" -ForegroundColor Green

# Step 10: Display information
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Deployment Complete!" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Access URLs:" -ForegroundColor Green
$frontendUrl = oc get route frontend-route -o jsonpath='{.spec.host}' 2>$null
$backendUrl = oc get route backend-route -o jsonpath='{.spec.host}' 2>$null

if ($frontendUrl) {
    Write-Host "Frontend:    https://$frontendUrl" -ForegroundColor Yellow
} else {
    Write-Host "Frontend:    Route not found" -ForegroundColor Red
}

if ($backendUrl) {
    Write-Host "Backend API: https://$backendUrl" -ForegroundColor Yellow
} else {
    Write-Host "Backend API: Route not found" -ForegroundColor Red
}

Write-Host "`nUseful commands:" -ForegroundColor Green
Write-Host "  View pods:       " -NoNewline; Write-Host "oc get pods" -ForegroundColor Cyan
Write-Host "  View services:   " -NoNewline; Write-Host "oc get svc" -ForegroundColor Cyan
Write-Host "  View routes:     " -NoNewline; Write-Host "oc get routes" -ForegroundColor Cyan
Write-Host "  View logs:       " -NoNewline; Write-Host "oc logs -f <pod-name>" -ForegroundColor Cyan
Write-Host "  Scale app:       " -NoNewline; Write-Host "oc scale dc/backend --replicas=3" -ForegroundColor Cyan
Write-Host "  Delete all:      " -NoNewline; Write-Host "oc delete project $ProjectName" -ForegroundColor Cyan

Write-Host "`nVerifying deployment..." -ForegroundColor Yellow
Write-Host "`nPods:" -ForegroundColor Cyan
oc get pods

Write-Host "`nServices:" -ForegroundColor Cyan
oc get svc

Write-Host "`nRoutes:" -ForegroundColor Cyan
oc get routes

Write-Host "`n========================================`n" -ForegroundColor Cyan
