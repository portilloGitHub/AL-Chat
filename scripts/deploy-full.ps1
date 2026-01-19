# PowerShell script to build and push AL-Chat Backend Docker image to ECR
# Usage: .\scripts\deploy-full.ps1 [staging|production]
# Default: production
# Note: Frontend is handled by main website project

param(
    [Parameter(Position=0)]
    [ValidateSet("staging", "production")]
    [string]$Environment = "production"
)

$ErrorActionPreference = "Stop"

# Configuration
$AWS_REGION = if ($env:AWS_REGION) { $env:AWS_REGION } else { "us-east-2" }
$AWS_ACCOUNT_ID = "542784561925"
$ECR_REPO_BACKEND = "al-chat-backend"

Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host "Deploying AL-Chat Backend to ECR" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host ""
Write-Host "Configuration:" -ForegroundColor White
Write-Host "   Environment: $Environment" -ForegroundColor Gray
Write-Host "   AWS Account: $AWS_ACCOUNT_ID" -ForegroundColor Gray
Write-Host "   Region: $AWS_REGION" -ForegroundColor Gray
Write-Host "   Note: Frontend is handled by main website project" -ForegroundColor Gray
Write-Host ""

# Authenticate with ECR first
Write-Host "Authenticating with ECR..." -ForegroundColor Yellow
$loginPassword = aws ecr get-login-password --region $AWS_REGION 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "ECR authentication failed" -ForegroundColor Red
    Write-Host $loginPassword -ForegroundColor Red
    exit 1
}

$ecrRegistry = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
$loginPassword | docker login --username AWS --password-stdin $ecrRegistry 2>&1 | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker login failed" -ForegroundColor Red
    exit 1
}

Write-Host "Authenticated with ECR" -ForegroundColor Green
Write-Host ""

# ==========================================
# BACKEND
# ==========================================
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host "Building Backend..." -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host ""

# Determine image tag based on environment
if ($Environment -eq "staging") {
    $IMAGE_TAG = "staging"
} else {
    $IMAGE_TAG = "latest"
}

$BACKEND_IMAGE_NAME = "al-chat-backend"
$BACKEND_ECR_URL = "${ecrRegistry}/${ECR_REPO_BACKEND}:${IMAGE_TAG}"

Write-Host "Step 1: Building backend Docker image..." -ForegroundColor Yellow
docker build -t "${BACKEND_IMAGE_NAME}:latest" -f Backend/Dockerfile Backend/

if ($LASTEXITCODE -ne 0) {
    Write-Host "Backend build failed" -ForegroundColor Red
    exit 1
}

Write-Host "Backend build complete" -ForegroundColor Green
Write-Host ""

Write-Host "Step 2: Tagging backend image..." -ForegroundColor Yellow
docker tag "${BACKEND_IMAGE_NAME}:latest" $BACKEND_ECR_URL

Write-Host "Step 3: Pushing backend to ECR..." -ForegroundColor Yellow
docker push $BACKEND_ECR_URL

if ($LASTEXITCODE -ne 0) {
    Write-Host "Backend push failed" -ForegroundColor Red
    exit 1
}

Write-Host "Backend pushed: $BACKEND_ECR_URL" -ForegroundColor Green
Write-Host ""

# Summary
Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host ""
Write-Host "Backend Image: $BACKEND_ECR_URL" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "   Deploy to staging EC2:" -ForegroundColor Gray
Write-Host "   .\scripts\deploy-to-staging.ps1" -ForegroundColor Cyan
Write-Host ""
