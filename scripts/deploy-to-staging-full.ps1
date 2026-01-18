# Deploy AL-Chat (Backend + Frontend) to staging EC2
# Usage: .\scripts\deploy-to-staging-full.ps1

$SSH_KEY = Join-Path $env:USERPROFILE ".ssh\papita-ec2-key.pem"
$STAGING_IP = "3.145.42.104"
$STAGING_USER = "ubuntu"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Deploying AL-Chat (Backend + Frontend) to Staging EC2" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $SSH_KEY)) {
    Write-Host "SSH key not found: $SSH_KEY" -ForegroundColor Red
    exit 1
}

Write-Host "SSH key found" -ForegroundColor Green
Write-Host "Connecting to staging EC2...`n" -ForegroundColor Yellow

# Deploy script to run on EC2
$deployScript = @'
#!/bin/bash
set -e

AWS_REGION="us-east-2"
AWS_ACCOUNT_ID="542784561925"
ECR_REPO_BACKEND="al-chat-backend"
ECR_REPO_FRONTEND="al-chat-frontend"
IMAGE_TAG="staging"
BACKEND_ECR_URL="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_BACKEND}:${IMAGE_TAG}"
FRONTEND_ECR_URL="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_FRONTEND}:${IMAGE_TAG}"

echo "Step 1: Authenticating with ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

echo ""
echo "Step 2: Pulling backend image..."
docker pull $BACKEND_ECR_URL

echo ""
echo "Step 3: Pulling frontend image..."
docker pull $FRONTEND_ECR_URL

echo ""
echo "Step 4: Stopping old containers..."
docker stop al-chat-backend-staging al-chat-frontend-staging 2>/dev/null || true
docker rm al-chat-backend-staging al-chat-frontend-staging 2>/dev/null || true

echo ""
echo "Step 5: Starting backend container..."
docker run -d \
  --name al-chat-backend-staging \
  -p 5001:5000 \
  --env-file ~/.env-al-chat \
  --restart unless-stopped \
  $BACKEND_ECR_URL

echo ""
echo "Step 6: Starting frontend container..."
docker run -d \
  --name al-chat-frontend-staging \
  -p 3001:80 \
  --restart unless-stopped \
  $FRONTEND_ECR_URL

echo ""
echo "Step 7: Waiting for containers to start..."
sleep 5

echo ""
echo "Step 8: Checking container status..."
docker ps | grep al-chat || echo "No containers running - check logs"

echo ""
echo "Step 9: Checking backend logs (last 10 lines)..."
docker logs al-chat-backend-staging --tail 10

echo ""
echo "Step 10: Testing backend health endpoint..."
curl -s http://localhost:5001/api/health || echo "Backend health check failed"

echo ""
echo "Step 11: Testing frontend..."
curl -s http://localhost:3001/health || curl -s http://localhost:3001 | head -n 5 || echo "Frontend check failed"

echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""
echo "Backend: http://localhost:5001/api/health"
echo "Frontend: http://localhost:3001"
'@

# Execute deployment script on EC2
Write-Host "Running deployment on EC2..." -ForegroundColor Yellow
$deployScript | ssh -i $SSH_KEY -o StrictHostKeyChecking=no ${STAGING_USER}@${STAGING_IP} "bash -s"

if ($LASTEXITCODE -ne 0) {
    Write-Host "`nDeployment failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "AL-Chat Staging Deployment Complete!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Test your staging deployment:" -ForegroundColor Yellow
Write-Host "   Backend API: http://${STAGING_IP}:5001/api/health" -ForegroundColor Gray
Write-Host "   Frontend: http://${STAGING_IP}:3001" -ForegroundColor Gray
Write-Host ""
