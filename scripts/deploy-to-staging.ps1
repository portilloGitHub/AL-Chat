# Complete AL-Chat Backend Deployment to Staging
# Usage: .\scripts\deploy-to-staging.ps1
# 
# This script handles the complete deployment workflow:
# 1. Build Docker image
# 2. Push to ECR
# 3. Deploy to EC2 staging
#
# Prerequisites:
# - AWS CLI configured
# - Docker running
# - SSH key at ~/.ssh/papita-ec2-key.pem
# - EC2 instance accessible

param(
    [switch]$SkipBuild = $false,
    [switch]$SkipECR = $false,
    [switch]$SkipDeploy = $false
)

$ErrorActionPreference = "Stop"

# ==========================================
# CONFIGURATION
# ==========================================
$AWS_REGION = if ($env:AWS_REGION) { $env:AWS_REGION } else { "us-east-2" }
$AWS_ACCOUNT_ID = "542784561925"
$ECR_REPO_BACKEND = "al-chat-backend"
$IMAGE_TAG = "staging"
$STAGING_IP = "3.145.42.104"
$STAGING_USER = "ubuntu"
$SSH_KEY = Join-Path $env:USERPROFILE ".ssh\papita-ec2-key.pem"
$BACKEND_IMAGE_NAME = "al-chat-backend"
$ecrRegistry = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
$BACKEND_ECR_URL = "${ecrRegistry}/${ECR_REPO_BACKEND}:${IMAGE_TAG}"

# ==========================================
# HEADER
# ==========================================
Write-Host ""
Write-Host ("=" * 70) -ForegroundColor Cyan
Write-Host "AL-Chat Backend - Complete Staging Deployment" -ForegroundColor Cyan
Write-Host ("=" * 70) -ForegroundColor Cyan
Write-Host ""
Write-Host "Configuration:" -ForegroundColor White
Write-Host "   Environment: staging" -ForegroundColor Gray
Write-Host "   AWS Account: $AWS_ACCOUNT_ID" -ForegroundColor Gray
Write-Host "   Region: $AWS_REGION" -ForegroundColor Gray
Write-Host "   ECR Repository: $ECR_REPO_BACKEND" -ForegroundColor Gray
Write-Host "   Image Tag: $IMAGE_TAG" -ForegroundColor Gray
Write-Host "   Staging EC2: $STAGING_IP" -ForegroundColor Gray
Write-Host ""

# ==========================================
# STEP 1: BUILD DOCKER IMAGE
# ==========================================
if (-not $SkipBuild) {
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host "STEP 1: Building Docker Image" -ForegroundColor Cyan
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Building backend Docker image..." -ForegroundColor Yellow
    Write-Host "   Context: Backend/" -ForegroundColor Gray
    Write-Host "   Dockerfile: Backend/Dockerfile" -ForegroundColor Gray
    Write-Host ""
    
    docker build -t "${BACKEND_IMAGE_NAME}:latest" -f Backend/Dockerfile Backend/
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Docker build failed" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "[OK] Docker image built successfully" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "[SKIP] Building Docker image (--SkipBuild)" -ForegroundColor Yellow
    Write-Host ""
}

# ==========================================
# STEP 2: AUTHENTICATE WITH ECR
# ==========================================
if (-not $SkipECR) {
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host "STEP 2: Authenticating with ECR" -ForegroundColor Cyan
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Authenticating with AWS ECR..." -ForegroundColor Yellow
    $loginPassword = aws ecr get-login-password --region $AWS_REGION 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] ECR authentication failed" -ForegroundColor Red
        Write-Host $loginPassword -ForegroundColor Red
        Write-Host ""
        Write-Host "Troubleshooting:" -ForegroundColor Yellow
        Write-Host "  1. Check AWS CLI is installed: aws --version" -ForegroundColor Gray
        Write-Host "  2. Check AWS credentials: aws configure list" -ForegroundColor Gray
        Write-Host "  3. Verify region: $AWS_REGION" -ForegroundColor Gray
        exit 1
    }
    
    $loginPassword | docker login --username AWS --password-stdin $ecrRegistry 2>&1 | Out-Null
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Docker login to ECR failed" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "[OK] Authenticated with ECR" -ForegroundColor Green
    Write-Host "   Registry: $ecrRegistry" -ForegroundColor Gray
    Write-Host ""
} else {
    Write-Host "[SKIP] ECR authentication (--SkipECR)" -ForegroundColor Yellow
    Write-Host ""
}

# ==========================================
# STEP 3: TAG AND PUSH TO ECR
# ==========================================
if (-not $SkipECR) {
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host "STEP 3: Tagging and Pushing to ECR" -ForegroundColor Cyan
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Tagging image..." -ForegroundColor Yellow
    Write-Host "   Source: ${BACKEND_IMAGE_NAME}:latest" -ForegroundColor Gray
    Write-Host "   Target: $BACKEND_ECR_URL" -ForegroundColor Gray
    docker tag "${BACKEND_IMAGE_NAME}:latest" $BACKEND_ECR_URL
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Image tagging failed" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "[OK] Image tagged" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "Pushing to ECR..." -ForegroundColor Yellow
    Write-Host "   This may take a few minutes..." -ForegroundColor Gray
    Write-Host ""
    
    docker push $BACKEND_ECR_URL
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Push to ECR failed" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "[OK] Image pushed to ECR" -ForegroundColor Green
    Write-Host "   Image: $BACKEND_ECR_URL" -ForegroundColor Gray
    Write-Host ""
} else {
    Write-Host "[SKIP] Pushing to ECR (--SkipECR)" -ForegroundColor Yellow
    Write-Host ""
}

# ==========================================
# STEP 4: DEPLOY TO EC2
# ==========================================
if (-not $SkipDeploy) {
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host "STEP 4: Deploying to EC2 Staging" -ForegroundColor Cyan
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host ""
    
    # Check SSH key
    if (-not (Test-Path $SSH_KEY)) {
        Write-Host "[ERROR] SSH key not found: $SSH_KEY" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please ensure the SSH key exists at:" -ForegroundColor Yellow
        Write-Host "  $SSH_KEY" -ForegroundColor Gray
        exit 1
    }
    
    Write-Host "[OK] SSH key found" -ForegroundColor Green
    Write-Host "   Key: $SSH_KEY" -ForegroundColor Gray
    Write-Host "   Target: ${STAGING_USER}@${STAGING_IP}" -ForegroundColor Gray
    Write-Host ""
    
    # Deploy script to run on EC2
    $deployScript = @"
#!/bin/bash
set -e

AWS_REGION="$AWS_REGION"
AWS_ACCOUNT_ID="$AWS_ACCOUNT_ID"
ECR_REPO_BACKEND="$ECR_REPO_BACKEND"
IMAGE_TAG="$IMAGE_TAG"
BACKEND_ECR_URL="`${AWS_ACCOUNT_ID}.dkr.ecr.`${AWS_REGION}.amazonaws.com/`${ECR_REPO_BACKEND}:`${IMAGE_TAG}"

echo "=========================================="
echo "Deploying AL-Chat Backend to EC2"
echo "=========================================="
echo ""

echo "[Step 1] Authenticating with ECR..."
aws ecr get-login-password --region `$AWS_REGION | docker login --username AWS --password-stdin `${AWS_ACCOUNT_ID}.dkr.ecr.`${AWS_REGION}.amazonaws.com

if [ `$? -ne 0 ]; then
    echo "[ERROR] ECR authentication failed"
    exit 1
fi

echo ""
echo "[Step 2] Pulling latest image from ECR..."
docker pull `$BACKEND_ECR_URL

if [ `$? -ne 0 ]; then
    echo "[ERROR] Failed to pull image from ECR"
    exit 1
fi

echo ""
echo "[Step 3] Stopping old container..."
docker stop al-chat-backend-staging 2>/dev/null || true
docker rm al-chat-backend-staging 2>/dev/null || true

echo ""
echo "[Step 4] Starting new container..."
docker run -d \
  --name al-chat-backend-staging \
  -p 5001:5000 \
  --env-file ~/.env-al-chat \
  --restart unless-stopped \
  `$BACKEND_ECR_URL

if [ `$? -ne 0 ]; then
    echo "[ERROR] Failed to start container"
    exit 1
fi

echo ""
echo "[Step 5] Waiting for container to start..."
sleep 5

echo ""
echo "[Step 6] Checking container status..."
docker ps | grep al-chat-backend-staging || echo "[WARNING] Container not found in running list"

echo ""
echo "[Step 7] Checking container logs (last 15 lines)..."
docker logs al-chat-backend-staging --tail 15

echo ""
echo "[Step 8] Testing health endpoint..."
HEALTH_RESPONSE=`$(curl -s -w "\nHTTP_CODE:%{http_code}" http://localhost:5001/api/health)
HTTP_CODE=`$(echo "`$HEALTH_RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
RESPONSE_BODY=`$(echo "`$HEALTH_RESPONSE" | grep -v "HTTP_CODE")

if [ "`$HTTP_CODE" = "200" ]; then
    echo "[OK] Backend is healthy"
    echo "Response: `$RESPONSE_BODY"
else
    echo "[WARNING] Health check returned HTTP `$HTTP_CODE"
    echo "Response: `$RESPONSE_BODY"
fi

echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""
echo "Backend API: http://localhost:5001/api/health"
echo "External URL: http://$STAGING_IP:5001/api/health"
echo ""
"@
    
    Write-Host "Connecting to EC2 and deploying..." -ForegroundColor Yellow
    Write-Host ""
    
    $deployScript | ssh -i $SSH_KEY -o StrictHostKeyChecking=no ${STAGING_USER}@${STAGING_IP} "bash -s"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "[ERROR] EC2 deployment failed" -ForegroundColor Red
        Write-Host ""
        Write-Host "Troubleshooting:" -ForegroundColor Yellow
        Write-Host "  1. Check SSH key permissions" -ForegroundColor Gray
        Write-Host "  2. Verify EC2 instance is running" -ForegroundColor Gray
        Write-Host "  3. Check Security Group allows SSH (port 22)" -ForegroundColor Gray
        Write-Host "  4. Verify AWS credentials on EC2 instance" -ForegroundColor Gray
        exit 1
    }
    
    Write-Host ""
    Write-Host "[OK] Deployment to EC2 completed" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "[SKIP] EC2 deployment (--SkipDeploy)" -ForegroundColor Yellow
    Write-Host ""
}

# ==========================================
# SUMMARY
# ==========================================
Write-Host ("=" * 70) -ForegroundColor Cyan
Write-Host "Deployment Summary" -ForegroundColor Cyan
Write-Host ("=" * 70) -ForegroundColor Cyan
Write-Host ""
Write-Host "[SUCCESS] AL-Chat Backend deployed to staging!" -ForegroundColor Green
Write-Host ""
Write-Host "Deployment Details:" -ForegroundColor White
Write-Host "   ECR Image: $BACKEND_ECR_URL" -ForegroundColor Gray
Write-Host "   EC2 Instance: $STAGING_IP" -ForegroundColor Gray
Write-Host "   Container: al-chat-backend-staging" -ForegroundColor Gray
Write-Host "   Port: 5001 (external) -> 5000 (internal)" -ForegroundColor Gray
Write-Host ""
Write-Host "Test Your Deployment:" -ForegroundColor Yellow
Write-Host "   Health Check: http://${STAGING_IP}:5001/api/health" -ForegroundColor Cyan
Write-Host "   API Base: http://${STAGING_IP}:5001/api" -ForegroundColor Cyan
Write-Host ""
Write-Host "Note: Frontend is handled by main website project" -ForegroundColor Gray
Write-Host ""
