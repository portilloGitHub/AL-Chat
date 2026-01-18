# AL-Chat Staging Deployment - Step by Step

Simple guide to build Docker image and deploy to EC2 staging.

## Prerequisites Check

1. ✅ Code pushed to GitHub
2. ✅ Docker Desktop running
3. ✅ AWS CLI configured (`aws configure`)
4. ✅ SSH key: `~/.ssh/papita-ec2-key.pem`

## Step 1: Create ECR Repository (One-Time)

**On your local machine:**

```powershell
aws ecr create-repository --repository-name al-chat-backend --region us-east-2
```

If repository already exists, you'll get an error - that's OK, it means it's already there.

## Step 2: Build and Push Docker Image to ECR

**On your local machine:**

```powershell
.\scripts\deploy.ps1 staging
```

This will:
1. Build Docker image from `Backend/Dockerfile`
2. Authenticate with AWS ECR
3. Tag image as `staging`
4. Push to ECR: `542784561925.dkr.ecr.us-east-2.amazonaws.com/al-chat-backend:staging`

## Step 3: Deploy to EC2 Staging

**On your local machine:**

```powershell
.\scripts\deploy-to-staging.ps1
```

This will SSH to EC2 and:
1. Pull the image from ECR
2. Stop old container
3. Start new container on port 5001

## Step 4: Verify Deployment

```powershell
# Test health endpoint
curl http://3.145.42.104:5001/api/health
```

Or open in browser: `http://3.145.42.104:5001/api/health`

## Troubleshooting

**ECR repository doesn't exist:**
```powershell
aws ecr create-repository --repository-name al-chat-backend --region us-east-2
```

**Docker not running:**
- Open Docker Desktop and wait until it's fully started

**AWS not configured:**
```powershell
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Region: us-east-2
# Output format: json
```

**Check if image was pushed:**
```powershell
aws ecr describe-images --repository-name al-chat-backend --region us-east-2
```
