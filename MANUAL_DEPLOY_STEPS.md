# Manual Deployment to EC2 Staging

Follow these steps to manually deploy AL-Chat to staging EC2.

## Step 1: SSH to Staging EC2

```bash
ssh -i ~/.ssh/papita-ec2-key.pem ubuntu@3.145.42.104
```

**Note:** If you're on Windows and the SSH key format doesn't work, try using WSL or Git Bash.

## Step 2: Authenticate with ECR

Once connected to EC2, run:

```bash
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 542784561925.dkr.ecr.us-east-2.amazonaws.com
```

## Step 3: Pull the Staging Image

```bash
docker pull 542784561925.dkr.ecr.us-east-2.amazonaws.com/al-chat-backend:staging
```

## Step 4: Create Environment File (First Time Only)

If `~/.env-al-chat` doesn't exist, create it:

```bash
nano ~/.env-al-chat
```

Add these variables:

```bash
OPENAI_API_KEY=sk-your-openai-api-key-here
OPENAI_MODEL=gpt-3.5-turbo
FLASK_ENV=staging
PORT=5000
AL_CHAT_LOG_DIR=/app/SessionLog
DEPLOYMENT_MODE=staging
```

Save and exit: `Ctrl+X`, then `Y`, then `Enter`

## Step 5: Stop Old Container (If Running)

```bash
docker stop al-chat-backend-staging 2>/dev/null || true
docker rm al-chat-backend-staging 2>/dev/null || true
```

## Step 6: Start New Container

```bash
docker run -d \
  --name al-chat-backend-staging \
  -p 5001:5000 \
  --env-file ~/.env-al-chat \
  --restart unless-stopped \
  542784561925.dkr.ecr.us-east-2.amazonaws.com/al-chat-backend:staging
```

## Step 7: Verify Deployment

```bash
# Check container status
docker ps | grep al-chat-backend-staging

# Check logs
docker logs al-chat-backend-staging --tail 20

# Test health endpoint
curl http://localhost:5001/api/health
```

## Step 8: Test from Outside EC2

From your local machine:

```powershell
curl http://3.145.42.104:5001/api/health
```

Or open in browser: `http://3.145.42.104:5001/api/health`

## Quick Reference - All Commands in Sequence

```bash
# 1. Authenticate
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 542784561925.dkr.ecr.us-east-2.amazonaws.com

# 2. Pull image
docker pull 542784561925.dkr.ecr.us-east-2.amazonaws.com/al-chat-backend:staging

# 3. Stop old container
docker stop al-chat-backend-staging 2>/dev/null || true
docker rm al-chat-backend-staging 2>/dev/null || true

# 4. Start new container
docker run -d \
  --name al-chat-backend-staging \
  -p 5001:5000 \
  --env-file ~/.env-al-chat \
  --restart unless-stopped \
  542784561925.dkr.ecr.us-east-2.amazonaws.com/al-chat-backend:staging

# 5. Verify
docker ps | grep al-chat-backend-staging
curl http://localhost:5001/api/health
```

## Troubleshooting

**Container won't start:**
```bash
docker logs al-chat-backend-staging
```

**Port 5001 already in use:**
```bash
# Check what's using the port
sudo netstat -tulpn | grep 5001

# Or check Docker containers
docker ps -a
```

**Environment file missing:**
- Make sure `~/.env-al-chat` exists (create in Step 4)

**ECR authentication fails:**
- Make sure AWS CLI is configured on EC2: `aws configure`

## Next Deployment

For future deployments, you only need:
1. SSH to EC2
2. Authenticate with ECR (Step 2)
3. Pull image (Step 3)
4. Stop old container (Step 5)
5. Start new container (Step 6)
6. Verify (Step 7)
