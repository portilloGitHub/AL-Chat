# Deploy AL-Chat to staging EC2 (papita-staging)
# Usage: .\scripts\deploy-to-staging.ps1

$SSH_KEY = Join-Path $env:USERPROFILE ".ssh\papita-ec2-key.pem"
$STAGING_IP = "3.145.42.104"  # Same staging server as main website
$STAGING_USER = "ubuntu"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Deploying AL-Chat to Staging EC2" -ForegroundColor Cyan
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
ECR_REPO="al-chat-backend"
IMAGE_TAG="staging"
ECR_URL="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}"

echo "Step 1: Authenticating with ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

echo "Step 2: Pulling staging image..."
docker pull $ECR_URL

echo "Step 3: Stopping old container..."
docker stop al-chat-backend-staging 2>/dev/null || true
docker rm al-chat-backend-staging 2>/dev/null || true

echo "Step 4: Starting new container..."
docker run -d \
  --name al-chat-backend-staging \
  -p 5001:5000 \
  --env-file ~/.env-al-chat \
  --restart unless-stopped \
  $ECR_URL

echo "Step 5: Waiting for container to start..."
sleep 5

echo "Step 6: Checking container status..."
docker ps | grep al-chat-backend-staging || echo "Container not running - check logs"

echo "Step 7: Checking logs (last 20 lines)..."
docker logs al-chat-backend-staging --tail 20

echo "Step 8: Testing health endpoint..."
curl -s http://localhost:5001/api/health || echo "Health check failed - check logs above"

echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
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
Write-Host "   Health: http://${STAGING_IP}:5001/api/health" -ForegroundColor Gray
Write-Host "   API: http://${STAGING_IP}:5001/api" -ForegroundColor Gray
Write-Host ""
