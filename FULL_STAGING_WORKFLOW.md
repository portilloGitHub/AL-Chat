# Complete Staging Deployment Workflow (Backend + Frontend)

Full workflow to deploy both backend and frontend to staging.

## Prerequisites Setup (One-Time)

### 1. Create Frontend ECR Repository

```powershell
aws ecr create-repository --repository-name al-chat-frontend --region us-east-2
```

Backend repository already exists: `al-chat-backend`

## After Developing Locally

### Step 1: Push Code to GitHub (Staging Branch)

```powershell
git checkout staging
git merge master
git push origin staging
```

### Step 2: Build and Push Both Docker Images to ECR

```powershell
.\scripts\deploy-full.ps1 staging
```

This will:
- Build backend Docker image
- Build frontend Docker image (with API URL configured)
- Push both to ECR

### Step 3: Deploy to EC2 Staging

**Manual deployment (SSH to EC2):**

```bash
# SSH to EC2
ssh -i ~/.ssh/papita-ec2-key.pem ubuntu@3.145.42.104

# Then on EC2, run:
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 542784561925.dkr.ecr.us-east-2.amazonaws.com

# Pull images
docker pull 542784561925.dkr.ecr.us-east-2.amazonaws.com/al-chat-backend:staging
docker pull 542784561925.dkr.ecr.us-east-2.amazonaws.com/al-chat-frontend:staging

# Stop old containers
docker stop al-chat-backend-staging al-chat-frontend-staging 2>/dev/null || true
docker rm al-chat-backend-staging al-chat-frontend-staging 2>/dev/null || true

# Start backend
docker run -d \
  --name al-chat-backend-staging \
  -p 5001:5000 \
  --env-file ~/.env-al-chat \
  --restart unless-stopped \
  542784561925.dkr.ecr.us-east-2.amazonaws.com/al-chat-backend:staging

# Start frontend
docker run -d \
  --name al-chat-frontend-staging \
  -p 3001:80 \
  --restart unless-stopped \
  542784561925.dkr.ecr.us-east-2.amazonaws.com/al-chat-frontend:staging

# Verify
docker ps | grep al-chat
curl http://localhost:5001/api/health
curl http://localhost:3001
```

### Step 4: Verify Deployment

**Backend API:**
```
http://3.145.42.104:5001/api/health
```

**Frontend:**
```
http://3.145.42.104:3001
```

## Quick Reference

**Three Steps:**
1. Push code: `git checkout staging && git merge master && git push origin staging`
2. Build and push images: `.\scripts\deploy-full.ps1 staging`
3. Deploy to EC2: Manual SSH (see Step 3 above)

## URLs

- **Backend API:** `http://3.145.42.104:5001/api`
- **Frontend:** `http://3.145.42.104:3001`
- **Backend Health:** `http://3.145.42.104:5001/api/health`

## Notes

- Frontend is configured to use backend API at: `http://3.145.42.104:5001/api`
- Frontend serves on port 3001 (nginx on port 80 inside container)
- Backend serves on port 5001 (Flask on port 5000 inside container)
- Both containers need Security Group ports open: 3001 and 5001
