#!/bin/bash
# Build and push AL-Chat Docker image to ECR
# Usage: ./scripts/deploy.sh [staging|production]
# Default: production

set -e

# Configuration
ENVIRONMENT=${1:-production}
AWS_REGION=${AWS_REGION:-us-east-2}
AWS_ACCOUNT_ID="542784561925"  # Same AWS Account ID as main website
ECR_REPO=al-chat-backend
IMAGE_NAME=al-chat-backend

# Tag based on environment
if [ "$ENVIRONMENT" == "staging" ]; then
    IMAGE_TAG="staging"
else
    IMAGE_TAG="latest"
fi

echo "=========================================="
echo "🚀 Deploying AL-Chat Backend to ECR"
echo "=========================================="
echo ""
echo "📋 Configuration:"
echo "   Environment: $ENVIRONMENT"
echo "   AWS Account: $AWS_ACCOUNT_ID"
echo "   Region: $AWS_REGION"
echo "   Repository: $ECR_REPO"
echo "   Image Tag: $IMAGE_TAG"
echo ""

# Build Docker image
echo "🔨 Step 1: Building Docker image..."
docker build -t ${IMAGE_NAME}:latest -f Backend/Dockerfile Backend/

if [ $? -ne 0 ]; then
    echo "❌ Docker build failed"
    exit 1
fi

echo "✅ Build complete"
echo ""

# Authenticate with ECR
echo "🔐 Step 2: Authenticating with ECR..."
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin \
  $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

if [ $? -ne 0 ]; then
    echo "❌ ECR authentication failed"
    echo ""
    echo "💡 Tip: Make sure AWS CLI is configured:"
    echo "   aws configure"
    exit 1
fi

echo "✅ Authenticated"
echo ""

# Tag image
ECR_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}"
echo "🏷️  Step 3: Tagging image..."
docker tag ${IMAGE_NAME}:latest $ECR_URL

echo "✅ Tagged: $ECR_URL"
echo ""

# Push to ECR
echo "📤 Step 4: Pushing to ECR..."
docker push $ECR_URL

if [ $? -ne 0 ]; then
    echo "❌ Push failed"
    echo ""
    echo "💡 Tip: Make sure ECR repository exists:"
    echo "   aws ecr create-repository --repository-name $ECR_REPO --region $AWS_REGION"
    exit 1
fi

echo "✅ Push complete"
echo ""

# Summary
echo "=========================================="
echo "✅ Deployment Complete!"
echo "=========================================="
echo ""
echo "📍 ECR Image: $ECR_URL"
echo ""
echo "🚀 Next Steps:"
echo "   Run deployment script to deploy on staging EC2:"
echo "   ./scripts/deploy-to-staging.sh"
echo ""
