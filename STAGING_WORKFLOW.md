# AL-Chat Staging Deployment Workflow

Simple numbered steps to deploy local changes to staging.

## After Developing Locally

### Step 1: Commit and Push Code to Master
```powershell
# Make sure you're on master branch
git checkout master

# Commit changes
git add .
git commit -m "Your commit message"

# Push to master
git push origin master
```

### Step 2: Push to Staging with Version Tag
```powershell
# Use script to merge master to staging and tag it
.\scripts\push-to-staging.ps1 [version]

# Examples:
.\scripts\push-to-staging.ps1        # Auto-increment patch version
.\scripts\push-to-staging.ps1 0.2.0  # Specify version manually
```

### Step 2: Build and Push Docker Image to ECR
```powershell
.\scripts\deploy.ps1 staging
```
This builds the Docker image and pushes it to AWS ECR.

### Step 3: Deploy to EC2 Staging

**Option A: Automated (if SSH key works)**
```powershell
.\scripts\deploy-to-staging.ps1
```

**Option B: Manual (current method)**
```bash
# SSH to EC2
ssh -i ~/.ssh/papita-ec2-key.pem ubuntu@3.145.42.104

# Then run these commands on EC2:
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 542784561925.dkr.ecr.us-east-2.amazonaws.com
docker pull 542784561925.dkr.ecr.us-east-2.amazonaws.com/al-chat-backend:staging
docker stop al-chat-backend-staging && docker rm al-chat-backend-staging
docker run -d --name al-chat-backend-staging -p 5001:5000 --env-file ~/.env-al-chat --restart unless-stopped 542784561925.dkr.ecr.us-east-2.amazonaws.com/al-chat-backend:staging
```

### Step 4: Verify Deployment
```powershell
curl http://3.145.42.104:5001/api/health
```

---

## Quick Reference

**Three Steps:**
1. Push code: `git checkout staging && git merge master && git push origin staging`
2. Push image: `.\scripts\deploy.ps1 staging`
3. Deploy to EC2: Manual SSH or `.\scripts\deploy-to-staging.ps1`
