#!/bin/bash
# Complete AL-Chat Backend Deployment to Staging
# Usage: ./scripts/deploy-to-staging.sh
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

set -e  # Exit on error

# Parse optional flags
SKIP_BUILD=false
SKIP_ECR=false
SKIP_DEPLOY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --skip-ecr)
            SKIP_ECR=true
            shift
            ;;
        --skip-deploy)
            SKIP_DEPLOY=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--skip-build] [--skip-ecr] [--skip-deploy]"
            exit 1
            ;;
    esac
done

# ==========================================
# CONFIGURATION
# ==========================================
AWS_REGION="${AWS_REGION:-us-east-2}"
AWS_ACCOUNT_ID="542784561925"
ECR_REPO_BACKEND="al-chat-backend"
IMAGE_TAG="staging"
STAGING_IP="3.145.42.104"
STAGING_USER="ubuntu"
SSH_KEY="$HOME/.ssh/papita-ec2-key.pem"
BACKEND_IMAGE_NAME="al-chat-backend"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
BACKEND_ECR_URL="${ECR_REGISTRY}/${ECR_REPO_BACKEND}:${IMAGE_TAG}"

# ==========================================
# HEADER
# ==========================================
echo ""
echo "======================================================================"
echo "AL-Chat Backend - Complete Staging Deployment"
echo "======================================================================"
echo ""
echo "Configuration:"
echo "   Environment: staging"
echo "   AWS Account: $AWS_ACCOUNT_ID"
echo "   Region: $AWS_REGION"
echo "   ECR Repository: $ECR_REPO_BACKEND"
echo "   Image Tag: $IMAGE_TAG"
echo "   Staging EC2: $STAGING_IP"
echo ""

# ==========================================
# STEP 1: BUILD DOCKER IMAGE
# ==========================================
if [ "$SKIP_BUILD" = false ]; then
    echo "======================================================================"
    echo "STEP 1: Building Docker Image"
    echo "======================================================================"
    echo ""
    
    echo "Building backend Docker image..."
    echo "   Context: Backend/"
    echo "   Dockerfile: Backend/Dockerfile"
    echo ""
    
    docker build -t "${BACKEND_IMAGE_NAME}:latest" -f Backend/Dockerfile Backend/
    
    if [ $? -ne 0 ]; then
        echo "[ERROR] Docker build failed"
        exit 1
    fi
    
    echo "[OK] Docker image built successfully"
    echo ""
else
    echo "[SKIP] Building Docker image (--skip-build)"
    echo ""
fi

# ==========================================
# STEP 2: AUTHENTICATE WITH ECR
# ==========================================
if [ "$SKIP_ECR" = false ]; then
    echo "======================================================================"
    echo "STEP 2: Authenticating with ECR"
    echo "======================================================================"
    echo ""
    
    echo "Authenticating with AWS ECR..."
    LOGIN_PASSWORD=$(aws ecr get-login-password --region $AWS_REGION 2>&1)
    
    if [ $? -ne 0 ]; then
        echo "[ERROR] ECR authentication failed"
        echo "$LOGIN_PASSWORD"
        echo ""
        echo "Troubleshooting:"
        echo "  1. Check AWS CLI is installed: aws --version"
        echo "  2. Check AWS credentials: aws configure list"
        echo "  3. Verify region: $AWS_REGION"
        exit 1
    fi
    
    echo "$LOGIN_PASSWORD" | docker login --username AWS --password-stdin $ECR_REGISTRY 2>&1 | grep -v "WARNING" || true
    
    if [ $? -ne 0 ]; then
        echo "[ERROR] Docker login to ECR failed"
        exit 1
    fi
    
    echo "[OK] Authenticated with ECR"
    echo "   Registry: $ECR_REGISTRY"
    echo ""
else
    echo "[SKIP] ECR authentication (--skip-ecr)"
    echo ""
fi

# ==========================================
# STEP 3: TAG AND PUSH TO ECR
# ==========================================
if [ "$SKIP_ECR" = false ]; then
    echo "======================================================================"
    echo "STEP 3: Tagging and Pushing to ECR"
    echo "======================================================================"
    echo ""
    
    echo "Tagging image..."
    echo "   Source: ${BACKEND_IMAGE_NAME}:latest"
    echo "   Target: $BACKEND_ECR_URL"
    docker tag "${BACKEND_IMAGE_NAME}:latest" "$BACKEND_ECR_URL"
    
    if [ $? -ne 0 ]; then
        echo "[ERROR] Image tagging failed"
        exit 1
    fi
    
    echo "[OK] Image tagged"
    echo ""
    
    echo "Pushing to ECR..."
    echo "   This may take a few minutes..."
    echo ""
    
    docker push "$BACKEND_ECR_URL"
    
    if [ $? -ne 0 ]; then
        echo "[ERROR] Push to ECR failed"
        exit 1
    fi
    
    echo "[OK] Image pushed to ECR"
    echo "   Image: $BACKEND_ECR_URL"
    echo ""
else
    echo "[SKIP] Pushing to ECR (--skip-ecr)"
    echo ""
fi

# ==========================================
# STEP 4: DEPLOY TO EC2
# ==========================================
if [ "$SKIP_DEPLOY" = false ]; then
    echo "======================================================================"
    echo "STEP 4: Deploying to EC2 Staging"
    echo "======================================================================"
    echo ""
    
    # Check SSH key
    if [ ! -f "$SSH_KEY" ]; then
        echo "[ERROR] SSH key not found: $SSH_KEY"
        echo ""
        echo "Please ensure the SSH key exists at:"
        echo "  $SSH_KEY"
        exit 1
    fi
    
    # Fix SSH key permissions if needed
    chmod 600 "$SSH_KEY" 2>/dev/null || true
    
    echo "[OK] SSH key found"
    echo "   Key: $SSH_KEY"
    echo "   Target: ${STAGING_USER}@${STAGING_IP}"
    echo ""
    
    # Deploy script to run on EC2
    DEPLOY_SCRIPT=$(cat <<'DEPLOY_EOF'
#!/bin/bash
set -e

AWS_REGION="us-east-2"
AWS_ACCOUNT_ID="542784561925"
ECR_REPO_BACKEND="al-chat-backend"
IMAGE_TAG="staging"
BACKEND_ECR_URL="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_BACKEND}:${IMAGE_TAG}"
STAGING_IP="3.145.42.104"

echo "=========================================="
echo "Deploying AL-Chat Backend to EC2"
echo "=========================================="
echo ""

echo "[Step 1] Authenticating with ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

if [ $? -ne 0 ]; then
    echo "[ERROR] ECR authentication failed"
    exit 1
fi

echo ""
echo "[Step 2] Pulling latest image from ECR..."
docker pull $BACKEND_ECR_URL

if [ $? -ne 0 ]; then
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
  -p 5000:5000 \
  --env-file ~/.env-al-chat \
  --restart unless-stopped \
  $BACKEND_ECR_URL

if [ $? -ne 0 ]; then
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
HEALTH_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" http://localhost:5000/api/health)
HTTP_CODE=$(echo "$HEALTH_RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
RESPONSE_BODY=$(echo "$HEALTH_RESPONSE" | grep -v "HTTP_CODE")

if [ "$HTTP_CODE" = "200" ]; then
    echo "[OK] Backend is healthy"
    echo "Response: $RESPONSE_BODY"
else
    echo "[WARNING] Health check returned HTTP $HTTP_CODE"
    echo "Response: $RESPONSE_BODY"
fi

echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""
echo "Backend API: http://localhost:5000/api/health"
echo "External URL: http://${STAGING_IP}:5000/api/health"
echo ""
DEPLOY_EOF
)
    
    echo "Connecting to EC2 and deploying..."
    echo ""
    
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no ${STAGING_USER}@${STAGING_IP} "bash -s" <<< "$DEPLOY_SCRIPT"
    
    if [ $? -ne 0 ]; then
        echo ""
        echo "[ERROR] EC2 deployment failed"
        echo ""
        echo "Troubleshooting:"
        echo "  1. Check SSH key permissions: chmod 600 $SSH_KEY"
        echo "  2. Verify EC2 instance is running"
        echo "  3. Check Security Group allows SSH (port 22)"
        echo "  4. Verify AWS credentials on EC2 instance"
        exit 1
    fi
    
    echo ""
    echo "[OK] Deployment to EC2 completed"
    echo ""
else
    echo "[SKIP] EC2 deployment (--skip-deploy)"
    echo ""
fi

# ==========================================
# SUMMARY
# ==========================================
echo "======================================================================"
echo "Deployment Summary"
echo "======================================================================"
echo ""
echo "[SUCCESS] AL-Chat Backend deployed to staging!"
echo ""
echo "Deployment Details:"
echo "   ECR Image: $BACKEND_ECR_URL"
echo "   EC2 Instance: $STAGING_IP"
echo "   Container: al-chat-backend-staging"
echo "   Port: 5000 (external) -> 5000 (internal)"
echo ""
echo "Test Your Deployment:"
echo "   Health Check: http://${STAGING_IP}:5000/api/health"
echo "   API Base: http://${STAGING_IP}:5000/api"
echo ""
echo "Note: Frontend is handled by main website project"
echo ""
