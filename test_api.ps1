# Test and populate the Public Transport Tracker API
# This script adds sample data to test the application

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Public Transport Tracker - API Test" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Test health endpoint
Write-Host "Testing API Health..." -ForegroundColor Yellow
try {
    $health = Invoke-WebRequest -Uri http://localhost:5000/api/health -UseBasicParsing | ConvertFrom-Json
    Write-Host "✓ API Status: $($health.status)" -ForegroundColor Green
    Write-Host "✓ Database: $($health.database)" -ForegroundColor Green
} catch {
    Write-Host "✗ API is not responding!" -ForegroundColor Red
    exit 1
}

Write-Host "`nCurrent Data Count:" -ForegroundColor Yellow
$routes = (Invoke-WebRequest -Uri http://localhost:5000/api/routes -UseBasicParsing | ConvertFrom-Json).data
$stations = (Invoke-WebRequest -Uri http://localhost:5000/api/stations -UseBasicParsing | ConvertFrom-Json).data
$schedules = (Invoke-WebRequest -Uri http://localhost:5000/api/schedules -UseBasicParsing | ConvertFrom-Json).data
$delays = (Invoke-WebRequest -Uri http://localhost:5000/api/delays -UseBasicParsing | ConvertFrom-Json).data

Write-Host "  Routes: $($routes.Count)" -ForegroundColor Cyan
Write-Host "  Stations: $($stations.Count)" -ForegroundColor Cyan
Write-Host "  Schedules: $($schedules.Count)" -ForegroundColor Cyan
Write-Host "  Delays: $($delays.Count)" -ForegroundColor Cyan

Write-Host "`nSample Routes:" -ForegroundColor Yellow
$routes | Format-Table route_id, route_name, route_type, start_station, end_station -AutoSize

Write-Host "Sample Stations:" -ForegroundColor Yellow
$stations | Format-Table station_id, station_name, station_type, latitude, longitude -AutoSize

Write-Host "Sample Schedules:" -ForegroundColor Yellow
$schedules | Format-Table schedule_id, route_name, departure_station, arrival_station, departure_time, arrival_time -AutoSize

Write-Host "Sample Delays:" -ForegroundColor Yellow
$delays | Format-Table delay_id, route_name, delay_minutes, reason, is_active -AutoSize

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Application URLs" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Frontend:    http://localhost" -ForegroundColor Green
Write-Host "  Backend API: http://localhost:5000/api" -ForegroundColor Green
Write-Host "  Health:      http://localhost:5000/api/health" -ForegroundColor Green
Write-Host "`n"
