# AL-Chat Staging Setup Guide (Matching Main Website)

This guide sets up AL-Chat staging deployment following the same process as the main website.

## Prerequisites

- AWS CLI configured (`aws configure`)
- Docker installed on local machine and staging EC2
- SSH key: `~/.ssh/papita-ec2-key.pem` (same as main website)
- Access to AWS ECR (same account: 542784561925)

## Step 1: Create ECR Repository (One-Time Setup)

**On your local machine:**

```bash
# Create ECR repository for AL-Chat
aws ecr create-repository \
  --repository-name al-chat-backend \
  --region us-east-2

# Or via PowerShell:
aws ecr create-repository --repository-name al-chat-backend --region us-east-2
```

This creates the repository: `542784561925.dkr.ecr.us-east-2.amazonaws.com/al-chat-backend`

## Step 2: Prepare Environment File on EC2 (One-Time Setup)

**SSH to staging EC2:**

```bash
ssh -i ~/.ssh/papita-ec2-key.pem ubuntu@3.145.42.104
```

**Create environment file:**

```bash
# Create .env-al-chat file
nano ~/.env-al-chat
```

Add these variables:
```bash
# OpenAI API Configuration (for local testing)
OPENAI_API_KEY=sk-your-key-here  # Optional - main site will pass this in production
OPENAI_MODEL=gpt-3.5-turbo

# Flask Configuration
FLASK_ENV=staging
PORT=5000
AL_CHAT_LOG_DIR=/app/SessionLog
DEPLOYMENT_MODE=staging
```

Save and exit (Ctrl+X, Y, Enter)

## Step 3: Deployment Workflow (Same as Main Website)

### Local Machine: Build and Push to ECR

**Windows PowerShell:**
```powershell
# Build and push staging image
.\scripts\deploy.ps1 staging
```

**Linux/Mac:**
```bash
# Build and push staging image
./scripts/deploy.sh staging
```

This will:
1. Build Docker image locally
2. Authenticate with ECR
3. Tag image as `staging`
4. Push to ECR: `542784561925.dkr.ecr.us-east-2.amazonaws.com/al-chat-backend:staging`

### Deploy to Staging EC2

**Windows PowerShell:**
```powershell
.\scripts\deploy-to-staging.ps1
```

**Linux/Mac:**
```bash
./scripts/deploy-to-staging.sh
```

This will SSH to EC2 and:
1. Authenticate with ECR
2. Pull staging image
3. Stop old container
4. Start new container on port 5001

## Step 4: Verify Deployment

**Test health endpoint:**
```bash
curl http://3.145.42.104:5001/api/health
```

**Or from browser:**
```
http://3.145.42.104:5001/api/health
```

## Quick Deployment Commands

```bash
# 1. Build and push (local machine)
.\scripts\deploy.ps1 staging          # Windows
./scripts/deploy.sh staging           # Linux/Mac

# 2. Deploy to EC2 (local machine)
.\scripts\deploy-to-staging.ps1       # Windows
./scripts/deploy-to-staging.sh        # Linux/Mac

# 3. Check status (on EC2 via SSH)
docker ps | grep al-chat-backend-staging
docker logs al-chat-backend-staging --tail 20
```

## Update Process

When you make code changes:

1. **Commit to staging branch:**
   ```bash
   git checkout staging
   git merge master
   git push origin staging
   ```

2. **Build and push:**
   ```powershell
   .\scripts\deploy.ps1 staging
   ```

3. **Deploy to EC2:**
   ```powershell
   .\scripts\deploy-to-staging.ps1
   ```

## Troubleshooting

### ECR Repository Not Found

```bash
# Create repository
aws ecr create-repository --repository-name al-chat-backend --region us-east-2
```

### Docker Build Fails

```bash
# Test build locally first
cd Backend
docker build -t al-chat-backend:test .
```

### EC2 Deployment Fails

**Check SSH key:**
```bash
ls ~/.ssh/papita-ec2-key.pem
```

**Check EC2 access:**
```bash
ssh -i ~/.ssh/papita-ec2-key.pem ubuntu@3.145.42.104
```

**Check environment file exists on EC2:**
```bash
cat ~/.env-al-chat
```

### Container Not Starting

**SSH to EC2 and check logs:**
```bash
ssh -i ~/.ssh/papita-ec2-key.pem ubuntu@3.145.42.104
docker logs al-chat-backend-staging
docker ps -a | grep al-chat-backend-staging
```

## Port Configuration

- **AL-Chat Staging:** Port `5001` (different from main website's port 3000)
- **Main Website Staging:** Port `3000`

This allows both services to run on the same EC2 instance.

## Integration with Main Website

When AL-Chat is integrated into main website's reverse proxy:

1. Main website will route `/api/al-chat/*` to `al-chat-backend-staging:5000`
2. AL-Chat container runs on internal Docker network
3. Port 5001 may not need to be exposed externally (internal network only)

## Environment Variables

**On EC2 (`~/.env-al-chat`):**
- `OPENAI_API_KEY` - For local testing (optional in production)
- `OPENAI_MODEL` - Model to use
- `FLASK_ENV` - Set to `staging`
- `DEPLOYMENT_MODE` - Set to `staging`

In production, OpenAI API key will be passed from main website's auth middleware.

## Next Steps

1. ✅ Create ECR repository (Step 1)
2. ✅ Set up environment file on EC2 (Step 2)
3. ✅ Test first deployment (Step 3)
4. 🔄 Integrate with main website's reverse proxy (future)
5. 🔄 Configure monitoring and logging (future)
