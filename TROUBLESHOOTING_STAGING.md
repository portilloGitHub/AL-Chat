# Troubleshooting Staging Deployment

## Connection Timeout Issue

If you get: `curl: (7) Failed to connect to 3.145.42.104 port 5001: Connection timed out`

### Step 1: Check Container is Running on EC2

SSH to EC2 and check:
```bash
ssh -i ~/.ssh/papita-ec2-key.pem ubuntu@3.145.42.104

# Check if container is running
docker ps | grep al-chat-backend-staging

# Check all containers (including stopped)
docker ps -a | grep al-chat-backend-staging
```

### Step 2: Check Container Logs

If container exists but not running:
```bash
docker logs al-chat-backend-staging
```

If container doesn't exist, it may have failed to start.

### Step 3: Test Locally on EC2

From inside EC2, test if the port works locally:
```bash
# Test health endpoint from EC2 itself
curl http://localhost:5001/api/health

# Or test with 127.0.0.1
curl http://127.0.0.1:5001/api/health
```

If this works, the issue is with external access (Security Group).

### Step 4: Check AWS Security Group

Port 5001 must be open in the EC2 Security Group:

**Via AWS Console:**
1. Go to EC2 → Instances → Select `papita-staging`
2. Go to Security tab
3. Click on Security Group
4. Inbound Rules → Check if port 5001 is open

**If port 5001 is not open, add it:**
- Type: Custom TCP
- Port: 5001
- Source: 0.0.0.0/0 (or your IP)
- Description: AL-Chat Backend Staging

**Via AWS CLI:**
```bash
aws ec2 describe-security-groups --instance-ids <instance-id> --region us-east-2
```

### Step 5: Verify Port is Bound

On EC2, check if port 5001 is listening:
```bash
sudo netstat -tulpn | grep 5001
# OR
sudo ss -tulpn | grep 5001
```

Should show: `0.0.0.0:5001` or `:::5001`

### Step 6: Restart Container (If Needed)

If container is not running:
```bash
# Check logs first
docker logs al-chat-backend-staging

# Restart container
docker start al-chat-backend-staging

# Or recreate it
docker stop al-chat-backend-staging 2>/dev/null || true
docker rm al-chat-backend-staging 2>/dev/null || true
docker run -d --name al-chat-backend-staging -p 5001:5000 --env-file ~/.env-al-chat --restart unless-stopped 542784561925.dkr.ecr.us-east-2.amazonaws.com/al-chat-backend:staging
```

## Common Issues

### Container Exited Immediately

Check logs:
```bash
docker logs al-chat-backend-staging
```

Common causes:
- Missing `.env-al-chat` file
- Invalid environment variables
- Application error

### Port Already in Use

```bash
# Check what's using port 5001
sudo lsof -i :5001

# Stop conflicting container
docker ps -a | grep 5001
```

### Security Group Not Configured

Port 5001 must be open in Security Group for external access.

## Quick Diagnostic Commands

Run these on EC2:
```bash
# 1. Container status
docker ps -a | grep al-chat

# 2. Container logs
docker logs al-chat-backend-staging --tail 50

# 3. Test locally on EC2
curl http://localhost:5001/api/health

# 4. Check port binding
sudo netstat -tulpn | grep 5001

# 5. Check if container has correct port mapping
docker inspect al-chat-backend-staging | grep -i port
```
