# Staging deployment script for AL-Chat (PowerShell)
# Usage: .\deploy\staging-deploy.ps1

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Green
Write-Host "  AL-Chat Staging Deployment" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Check if Docker is running
try {
    docker info | Out-Null
    Write-Host "[OK] Docker is running" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Docker is not running" -ForegroundColor Red
    exit 1
}

# Check if staging compose file exists
if (-not (Test-Path "docker-compose.staging.yml")) {
    Write-Host "[ERROR] docker-compose.staging.yml not found" -ForegroundColor Red
    exit 1
}

# Stop existing staging containers
Write-Host "[INFO] Stopping existing staging containers..." -ForegroundColor Yellow
docker-compose -f docker-compose.staging.yml down 2>&1 | Out-Null

# Build and start staging containers
Write-Host "[INFO] Building and starting staging containers..." -ForegroundColor Yellow
docker-compose -f docker-compose.staging.yml build --no-cache
docker-compose -f docker-compose.staging.yml up -d

# Wait for health check
Write-Host "[INFO] Waiting for backend to be healthy..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Check health
$maxAttempts = 30
$attempt = 0
$healthy = $false

while ($attempt -lt $maxAttempts) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:5001/api/health" -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop
        Write-Host "[OK] Backend is healthy" -ForegroundColor Green
        $healthy = $true
        break
    } catch {
        $attempt++
        Write-Host "Waiting for backend... (attempt $attempt/$maxAttempts)" -ForegroundColor Yellow
        Start-Sleep -Seconds 2
    }
}

if (-not $healthy) {
    Write-Host "[ERROR] Backend health check failed" -ForegroundColor Red
    docker-compose -f docker-compose.staging.yml logs al-chat-backend
    exit 1
}

# Show status
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Deployment Complete" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Staging backend is running on: http://localhost:5001" -ForegroundColor Cyan
Write-Host ""
Write-Host "To view logs: docker-compose -f docker-compose.staging.yml logs -f" -ForegroundColor Cyan
Write-Host "To stop: docker-compose -f docker-compose.staging.yml down" -ForegroundColor Cyan
Write-Host ""
