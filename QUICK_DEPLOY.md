# AL-Chat Quick Deploy (Staging)

Fast deployment commands matching main website workflow.

## Deploy to Staging (Two Commands)

### 1. Build and Push to ECR

**Windows:**
```powershell
.\scripts\deploy.ps1 staging
```

**Linux/Mac:**
```bash
./scripts/deploy.sh staging
```

### 2. Deploy to EC2

**Windows:**
```powershell
.\scripts\deploy-to-staging.ps1
```

**Linux/Mac:**
```bash
./scripts/deploy-to-staging.sh
```

## Verify

```bash
curl http://3.145.42.104:5001/api/health
```

## Full Workflow

```bash
# 1. Commit changes
git checkout staging
git merge master
git push origin staging

# 2. Build and push
.\scripts\deploy.ps1 staging

# 3. Deploy to EC2
.\scripts\deploy-to-staging.ps1
```

## Troubleshooting

**ECR repository missing:**
```bash
aws ecr create-repository --repository-name al-chat-backend --region us-east-2
```

**Check container status:**
```bash
ssh -i ~/.ssh/papita-ec2-key.pem ubuntu@3.145.42.104
docker ps | grep al-chat-backend-staging
```

**View logs:**
```bash
docker logs al-chat-backend-staging -f
```
