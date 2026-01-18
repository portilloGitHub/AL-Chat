# PowerShell script to build and push BOTH AL-Chat Backend and Frontend Docker images to ECR
# Usage: .\scripts\deploy-full.ps1 [staging|production]
# Default: production

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
$ECR_REPO_FRONTEND = "al-chat-frontend"
$STAGING_IP = "3.145.42.104"

# Determine image tag based on environment
if ($Environment -eq "staging") {
    $IMAGE_TAG = "staging"
    $REACT_APP_API_URL = "http://${STAGING_IP}:5001/api"
} else {
    $IMAGE_TAG = "latest"
    $REACT_APP_API_URL = "http://localhost:5000/api"
}

Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host "Deploying AL-Chat (Backend + Frontend) to ECR" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host ""
Write-Host "Configuration:" -ForegroundColor White
Write-Host "   Environment: $Environment" -ForegroundColor Gray
Write-Host "   AWS Account: $AWS_ACCOUNT_ID" -ForegroundColor Gray
Write-Host "   Region: $AWS_REGION" -ForegroundColor Gray
Write-Host "   API URL: $REACT_APP_API_URL" -ForegroundColor Gray
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

# ==========================================
# FRONTEND
# ==========================================
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host "Building Frontend..." -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host ""

$FRONTEND_IMAGE_NAME = "al-chat-frontend"
$FRONTEND_ECR_URL = "${ecrRegistry}/${ECR_REPO_FRONTEND}:${IMAGE_TAG}"

Write-Host "Step 4: Building frontend Docker image..." -ForegroundColor Yellow
Write-Host "   API URL: $REACT_APP_API_URL" -ForegroundColor Gray
docker build -t "${FRONTEND_IMAGE_NAME}:latest" --build-arg REACT_APP_API_URL=$REACT_APP_API_URL -f Frontend/Dockerfile Frontend/

if ($LASTEXITCODE -ne 0) {
    Write-Host "Frontend build failed" -ForegroundColor Red
    exit 1
}

Write-Host "Frontend build complete" -ForegroundColor Green
Write-Host ""

Write-Host "Step 5: Tagging frontend image..." -ForegroundColor Yellow
docker tag "${FRONTEND_IMAGE_NAME}:latest" $FRONTEND_ECR_URL

Write-Host "Step 6: Pushing frontend to ECR..." -ForegroundColor Yellow
docker push $FRONTEND_ECR_URL

if ($LASTEXITCODE -ne 0) {
    Write-Host "Frontend push failed" -ForegroundColor Red
    exit 1
}

Write-Host "Frontend pushed: $FRONTEND_ECR_URL" -ForegroundColor Green
Write-Host ""

# Summary
Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host ""
Write-Host "Backend Image: $BACKEND_ECR_URL" -ForegroundColor White
Write-Host "Frontend Image: $FRONTEND_ECR_URL" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "   Deploy to staging EC2:" -ForegroundColor Gray
Write-Host "   .\scripts\deploy-to-staging-full.ps1" -ForegroundColor Cyan
Write-Host ""
