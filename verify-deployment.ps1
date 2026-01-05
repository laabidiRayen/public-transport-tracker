# OpenShift Deployment Verification Script
# Checks if all components are properly deployed

param(
    [string]$ProjectName = "transport-tracker"
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  OpenShift Deployment Verification" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Switch to project
Write-Host "Checking project..." -ForegroundColor Yellow
try {
    oc project $ProjectName | Out-Null
    Write-Host "✓ Project: $ProjectName" -ForegroundColor Green
} catch {
    Write-Host "✗ Project not found: $ProjectName" -ForegroundColor Red
    exit 1
}

# Check ConfigMaps
Write-Host "`nChecking ConfigMaps..." -ForegroundColor Yellow
$configMaps = oc get configmap transport-config 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ ConfigMap: transport-config" -ForegroundColor Green
} else {
    Write-Host "✗ ConfigMap not found" -ForegroundColor Red
}

# Check Secrets
Write-Host "`nChecking Secrets..." -ForegroundColor Yellow
$secrets = oc get secret transport-secrets 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Secret: transport-secrets" -ForegroundColor Green
} else {
    Write-Host "✗ Secret not found" -ForegroundColor Red
}

# Check ImageStreams
Write-Host "`nChecking ImageStreams..." -ForegroundColor Yellow
$backendIS = oc get is backend 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ ImageStream: backend" -ForegroundColor Green
} else {
    Write-Host "✗ ImageStream backend not found" -ForegroundColor Red
}

$frontendIS = oc get is frontend 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ ImageStream: frontend" -ForegroundColor Green
} else {
    Write-Host "✗ ImageStream frontend not found" -ForegroundColor Red
}

# Check BuildConfigs
Write-Host "`nChecking BuildConfigs..." -ForegroundColor Yellow
$backendBC = oc get bc backend 2>$null
if ($LASTEXITCODE -eq 0) {
    $buildStatus = oc get builds -l buildconfig=backend --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1].status.phase}' 2>$null
    Write-Host "✓ BuildConfig: backend (Last build: $buildStatus)" -ForegroundColor Green
} else {
    Write-Host "✗ BuildConfig backend not found" -ForegroundColor Red
}

$frontendBC = oc get bc frontend 2>$null
if ($LASTEXITCODE -eq 0) {
    $buildStatus = oc get builds -l buildconfig=frontend --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1].status.phase}' 2>$null
    Write-Host "✓ BuildConfig: frontend (Last build: $buildStatus)" -ForegroundColor Green
} else {
    Write-Host "✗ BuildConfig frontend not found" -ForegroundColor Red
}

# Check DeploymentConfigs
Write-Host "`nChecking DeploymentConfigs..." -ForegroundColor Yellow
$dcs = @("backend", "backend-sqlite", "frontend", "postgres")
foreach ($dc in $dcs) {
    $exists = oc get dc $dc 2>$null
    if ($LASTEXITCODE -eq 0) {
        $replicas = oc get dc $dc -o jsonpath='{.status.availableReplicas}' 2>$null
        $desired = oc get dc $dc -o jsonpath='{.spec.replicas}' 2>$null
        if ($replicas -eq $desired) {
            Write-Host "✓ DeploymentConfig: $dc ($replicas/$desired replicas)" -ForegroundColor Green
        } else {
            Write-Host "⚠ DeploymentConfig: $dc ($replicas/$desired replicas)" -ForegroundColor Yellow
        }
    }
}

# Check Services
Write-Host "`nChecking Services..." -ForegroundColor Yellow
$services = @("backend-service", "backend-sqlite-service", "frontend-service", "postgres-service")
foreach ($svc in $services) {
    $exists = oc get svc $svc 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Service: $svc" -ForegroundColor Green
    }
}

# Check Routes
Write-Host "`nChecking Routes..." -ForegroundColor Yellow
$frontendRoute = oc get route frontend-route 2>$null
if ($LASTEXITCODE -eq 0) {
    $frontendHost = oc get route frontend-route -o jsonpath='{.spec.host}'
    Write-Host "✓ Route: frontend-route" -ForegroundColor Green
    Write-Host "  URL: https://$frontendHost" -ForegroundColor Cyan
} else {
    Write-Host "✗ Route frontend-route not found" -ForegroundColor Red
}

$backendRoute = oc get route backend-route 2>$null
if ($LASTEXITCODE -eq 0) {
    $backendHost = oc get route backend-route -o jsonpath='{.spec.host}'
    Write-Host "✓ Route: backend-route" -ForegroundColor Green
    Write-Host "  URL: https://$backendHost" -ForegroundColor Cyan
} else {
    Write-Host "✗ Route backend-route not found" -ForegroundColor Red
}

# Check PVCs
Write-Host "`nChecking PersistentVolumeClaims..." -ForegroundColor Yellow
$pvcs = @("postgres-pvc", "sqlite-pvc")
foreach ($pvc in $pvcs) {
    $exists = oc get pvc $pvc 2>$null
    if ($LASTEXITCODE -eq 0) {
        $status = oc get pvc $pvc -o jsonpath='{.status.phase}'
        if ($status -eq "Bound") {
            Write-Host "✓ PVC: $pvc (Bound)" -ForegroundColor Green
        } else {
            Write-Host "⚠ PVC: $pvc ($status)" -ForegroundColor Yellow
        }
    }
}

# Check Pods
Write-Host "`nChecking Pods..." -ForegroundColor Yellow
Write-Host ""
oc get pods

# Test Backend Health
Write-Host "`nTesting Backend Health..." -ForegroundColor Yellow
try {
    $backendHost = oc get route backend-route -o jsonpath='{.spec.host}' 2>$null
    if ($backendHost) {
        $health = Invoke-WebRequest -Uri "https://$backendHost/api/health" -UseBasicParsing -TimeoutSec 10 2>$null | ConvertFrom-Json
        if ($health.status -eq "healthy") {
            Write-Host "✓ Backend API is healthy" -ForegroundColor Green
            Write-Host "  Database: $($health.database)" -ForegroundColor Cyan
        } else {
            Write-Host "⚠ Backend responded but not healthy" -ForegroundColor Yellow
        }
    } else {
        Write-Host "⚠ Backend route not available" -ForegroundColor Yellow
    }
} catch {
    Write-Host "✗ Cannot reach backend API" -ForegroundColor Red
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Verification Complete" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Quick Access Commands:" -ForegroundColor Green
Write-Host "  View all resources:  " -NoNewline; Write-Host "oc get all" -ForegroundColor Cyan
Write-Host "  View logs:           " -NoNewline; Write-Host "oc logs -f dc/backend" -ForegroundColor Cyan
Write-Host "  Scale backend:       " -NoNewline; Write-Host "oc scale dc/backend --replicas=3" -ForegroundColor Cyan
Write-Host "  Port forward:        " -NoNewline; Write-Host "oc port-forward svc/backend-service 5000:5000" -ForegroundColor Cyan

Write-Host "`n"
