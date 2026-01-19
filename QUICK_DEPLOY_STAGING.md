# Quick Deploy to Staging

## Single Command Deployment

Deploy AL-Chat backend to staging EC2 with one command:

```powershell
.\scripts\deploy-to-staging.ps1
```

This single script handles:
1. ✅ Builds Docker image
2. ✅ Authenticates with AWS ECR
3. ✅ Tags and pushes image to ECR
4. ✅ Deploys to EC2 staging
5. ✅ Verifies deployment

## Prerequisites

- **AWS CLI** configured with credentials
- **Docker** running locally
- **SSH key** at `~/.ssh/papita-ec2-key.pem`
- **EC2 instance** accessible at `3.145.42.104`

## Optional Flags

Skip specific steps if needed:

```powershell
# Skip Docker build (if image already built)
.\scripts\deploy-to-staging.ps1 -SkipBuild

# Skip ECR push (if already pushed)
.\scripts\deploy-to-staging.ps1 -SkipECR

# Skip EC2 deployment (if only pushing to ECR)
.\scripts\deploy-to-staging.ps1 -SkipDeploy

# Combine flags
.\scripts\deploy-to-staging.ps1 -SkipBuild -SkipECR
```

## What Happens

### Step 1: Build Docker Image
- Builds from `Backend/Dockerfile`
- Tags as `al-chat-backend:latest`

### Step 2: Authenticate with ECR
- Authenticates with AWS ECR
- Region: `us-east-2`
- Account: `542784561925`

### Step 3: Push to ECR
- Tags image as `staging`
- Pushes to: `542784561925.dkr.ecr.us-east-2.amazonaws.com/al-chat-backend:staging`

### Step 4: Deploy to EC2
- SSH to staging EC2 (`3.145.42.104`)
- Pulls latest image from ECR
- Stops old container
- Starts new container on port `5001:5000`
- Uses environment file: `~/.env-al-chat`

### Step 5: Verify
- Checks container status
- Tests health endpoint: `http://localhost:5001/api/health`
- Shows container logs

## After Deployment

**Test your deployment:**
```powershell
curl http://3.145.42.104:5001/api/health
```

**Expected response:**
```json
{
  "status": "healthy",
  "timestamp": "...",
  "openai_configured": true
}
```

## Troubleshooting

### Build Fails
- Check Docker is running
- Verify `Backend/Dockerfile` exists
- Check `Backend/requirements.txt` is valid

### ECR Authentication Fails
- Verify AWS CLI: `aws --version`
- Check credentials: `aws configure list`
- Verify region: `us-east-2`

### EC2 Deployment Fails
- Check SSH key exists: `~/.ssh/papita-ec2-key.pem`
- Verify EC2 instance is running
- Check Security Group allows SSH (port 22)
- Verify AWS credentials on EC2 instance

### Container Won't Start
- Check environment file exists on EC2: `~/.env-al-chat`
- Verify port 5001 is not in use
- Check container logs: `docker logs al-chat-backend-staging`

## Environment Variables on EC2

Ensure `~/.env-al-chat` on EC2 contains:
```bash
FLASK_ENV=staging
PORT=5000
PAPITA_API_URL=http://<papita-staging-url>:3000
OPENAI_API_KEY=<optional-if-using-papita>
OPENAI_MODEL=gpt-3.5-turbo
```

## Integration with Main Website

After deployment, the main website can connect to:
- **Backend API:** `http://3.145.42.104:5001/api`
- **Health Check:** `http://3.145.42.104:5001/api/health`

The main website's `ChatWindow.js` should point to this URL in staging.
