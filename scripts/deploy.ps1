# PowerShell script to build and push AL-Chat Docker image to ECR
# Usage: .\scripts\deploy.ps1 [staging|production]
# Default: production

param(
    [Parameter(Position=0)]
    [ValidateSet("staging", "production")]
    [string]$Environment = "production"
)

$ErrorActionPreference = "Stop"

# Configuration
$AWS_REGION = if ($env:AWS_REGION) { $env:AWS_REGION } else { "us-east-2" }
$AWS_ACCOUNT_ID = "542784561925"  # Same AWS Account ID as main website
$ECR_REPO = "al-chat-backend"
$IMAGE_NAME = "al-chat-backend"

# Determine image tag based on environment
if ($Environment -eq "staging") {
    $IMAGE_TAG = "staging"
} else {
    $IMAGE_TAG = "latest"
}

# Display configuration
Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host "Deploying AL-Chat Backend to ECR" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host ""
Write-Host "Configuration:" -ForegroundColor White
Write-Host "   Environment: $Environment" -ForegroundColor Gray
Write-Host "   AWS Account: $AWS_ACCOUNT_ID" -ForegroundColor Gray
Write-Host "   Region: $AWS_REGION" -ForegroundColor Gray
Write-Host "   Repository: $ECR_REPO" -ForegroundColor Gray
Write-Host "   Image Tag: $IMAGE_TAG" -ForegroundColor Gray
Write-Host ""

# Build Docker image
Write-Host "Step 1: Building Docker image..." -ForegroundColor Yellow
Write-Host "   This may take a few minutes..." -ForegroundColor Gray
Write-Host ""

# Build with output streaming to console
docker build -t "${IMAGE_NAME}:latest" -f Backend/Dockerfile Backend/

if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker build failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Build complete" -ForegroundColor Green
Write-Host ""

# Authenticate with ECR
Write-Host "Step 2: Authenticating with ECR..." -ForegroundColor Yellow

if ([string]::IsNullOrWhiteSpace($AWS_ACCOUNT_ID)) {
    Write-Host "Error: AWS_ACCOUNT_ID is empty!" -ForegroundColor Red
    exit 1
}

$loginPassword = aws ecr get-login-password --region $AWS_REGION 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "ECR authentication failed" -ForegroundColor Red
    Write-Host $loginPassword -ForegroundColor Red
    Write-Host ""
    Write-Host "Tip: Make sure AWS CLI is configured:" -ForegroundColor Yellow
    Write-Host "   aws configure" -ForegroundColor Gray
    exit 1
}

$ecrRegistry = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
Write-Host "   Logging into: $ecrRegistry" -ForegroundColor Gray
$loginPassword | docker login --username AWS --password-stdin $ecrRegistry 2>&1 | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker login failed" -ForegroundColor Red
    exit 1
}

Write-Host "Authenticated with ECR" -ForegroundColor Green
Write-Host ""

# Tag image
$ECR_URL = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}"
Write-Host "Step 3: Tagging image..." -ForegroundColor Yellow
docker tag "${IMAGE_NAME}:latest" $ECR_URL

if ($LASTEXITCODE -ne 0) {
    Write-Host "Image tagging failed" -ForegroundColor Red
    exit 1
}

Write-Host "Tagged: $ECR_URL" -ForegroundColor Green
Write-Host ""

# Push to ECR
Write-Host "Step 4: Pushing to ECR..." -ForegroundColor Yellow
Write-Host "   This may take a few minutes depending on image size..." -ForegroundColor Gray
Write-Host ""

$pushResult = docker push $ECR_URL 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "Push failed" -ForegroundColor Red
    Write-Host $pushResult -ForegroundColor Red
    Write-Host ""
    Write-Host "Tip: Make sure ECR repository exists:" -ForegroundColor Yellow
    Write-Host "   aws ecr create-repository --repository-name $ECR_REPO --region $AWS_REGION" -ForegroundColor Gray
    exit 1
}

Write-Host "Push complete" -ForegroundColor Green
Write-Host ""

# Summary
Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host ""
Write-Host "ECR Image: $ECR_URL" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "   Run deployment script to deploy on staging EC2:" -ForegroundColor Gray
Write-Host "   .\scripts\deploy-to-staging.ps1" -ForegroundColor Cyan
Write-Host ""
