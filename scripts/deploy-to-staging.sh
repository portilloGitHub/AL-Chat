#!/bin/bash
# Deploy AL-Chat to staging EC2 (papita-staging)
# Usage: ./scripts/deploy-to-staging.sh

set -e

# Configuration
STAGING_IP="3.145.42.104"  # Same staging server as main website
STAGING_USER="ubuntu"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/papita-ec2-key.pem}"
AWS_REGION="us-east-2"
AWS_ACCOUNT_ID="542784561925"
ECR_REPO="al-chat-backend"
IMAGE_TAG="staging"
ECR_URL="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}"

echo ""
echo "============================================================"
echo "🚀 Deploying AL-Chat to Staging EC2"
echo "============================================================"
echo ""
echo "📋 Configuration:"
echo "   EC2 IP: $STAGING_IP"
echo "   User: $STAGING_USER"
echo "   Image: $ECR_URL"
echo ""

# Check if SSH key exists
if [ ! -f "$SSH_KEY" ]; then
    echo "❌ SSH key not found: $SSH_KEY"
    echo ""
    echo "Please provide the SSH key path in one of these ways:"
    echo ""
    echo "Option 1: Set environment variable:"
    echo "   export SSH_KEY=/path/to/your/key.pem"
    echo "   ./scripts/deploy-to-staging.sh"
    echo ""
    exit 1
fi

echo "✅ SSH key found"
echo ""

echo "🔐 Connecting to staging EC2 (papita-staging)..."
echo ""

# Deploy script
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no ${STAGING_USER}@${STAGING_IP} << 'EOF'
set -e

# Configuration
AWS_REGION="us-east-2"
AWS_ACCOUNT_ID="542784561925"
ECR_REPO="al-chat-backend"
IMAGE_TAG="staging"
ECR_URL="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}"

echo "🔐 Step 1: Authenticating with ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

echo "📥 Step 2: Pulling staging image..."
docker pull $ECR_URL

echo "🛑 Step 3: Stopping old container..."
docker stop al-chat-backend-staging 2>/dev/null || true
docker rm al-chat-backend-staging 2>/dev/null || true

echo "🚀 Step 4: Starting new container..."
docker run -d \
  --name al-chat-backend-staging \
  -p 5001:5000 \
  --env-file ~/.env-al-chat \
  --restart unless-stopped \
  $ECR_URL

echo "⏳ Step 5: Waiting for container to start..."
sleep 5

echo "📋 Step 6: Checking container status..."
docker ps | grep al-chat-backend-staging || echo "Container not running - check logs"

echo "📝 Step 7: Checking logs (last 20 lines)..."
docker logs al-chat-backend-staging --tail 20

echo "✅ Step 8: Testing health endpoint..."
curl -s http://localhost:5001/api/health || echo "Health check failed - check logs above"

echo ""
echo "=========================================="
echo "✅ Deployment Complete!"
echo "=========================================="
EOF

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Deployment failed"
    exit 1
fi

echo ""
echo "============================================================"
echo "✅ AL-Chat Staging Deployment Complete!"
echo "============================================================"
echo ""
echo "🌐 Test your staging deployment:"
echo "   Health: http://${STAGING_IP}:5001/api/health"
echo "   API: http://${STAGING_IP}:5001/api"
echo ""
