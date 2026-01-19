# Troubleshooting Staging Connection Issues

## Common Error: ERR_CONNECTION_TIMED_OUT

If you see `ERR_CONNECTION_TIMED_OUT` when trying to connect to the AL-Chat backend on staging, check these:

### 1. Check if Container is Running

SSH into EC2 and check:
```bash
ssh -i ~/.ssh/papita-ec2-key.pem ubuntu@3.145.42.104
docker ps | grep al-chat-backend-staging
```

If container is not running:
```bash
docker ps -a | grep al-chat-backend-staging  # Check if it exists but stopped
docker logs al-chat-backend-staging --tail 50  # Check logs for errors
```

### 2. Check Port Mapping

Verify the container is using port 5000:
```bash
docker ps | grep al-chat-backend-staging
# Should show: 0.0.0.0:5000->5000/tcp
```

If it shows `5001:5000`, the container needs to be redeployed with the new configuration.

### 3. Check AWS Security Group

The Security Group must allow inbound traffic on port 5000:

**AWS Console:**
1. Go to EC2 → Security Groups
2. Find the security group for your EC2 instance
3. Check Inbound Rules
4. Ensure there's a rule allowing:
   - Type: Custom TCP
   - Port: 5000
   - Source: 0.0.0.0/0 (or your IP)

**Using AWS CLI:**
```bash
aws ec2 describe-security-groups --group-ids <your-security-group-id> --query 'SecurityGroups[0].IpPermissions'
```

### 4. Redeploy with New Port Configuration

If the container is still using port 5001, redeploy:

```bash
# From your local machine (Git Bash)
./scripts/deploy-to-staging.sh
```

This will:
- Build new Docker image
- Push to ECR
- Pull and restart container on EC2 with port 5000

### 5. Test Connection Locally on EC2

SSH into EC2 and test from inside:
```bash
ssh -i ~/.ssh/papita-ec2-key.pem ubuntu@3.145.42.104
curl http://localhost:5000/api/health
```

If this works but external connection doesn't, it's a Security Group issue.

### 6. Check Container Logs

```bash
ssh -i ~/.ssh/papita-ec2-key.pem ubuntu@3.145.42.104
docker logs al-chat-backend-staging --tail 50
```

Look for:
- Startup errors
- Port binding errors
- Application crashes

### 7. Restart Container

If container is running but not responding:
```bash
ssh -i ~/.ssh/papita-ec2-key.pem ubuntu@3.145.42.104 'docker restart al-chat-backend-staging'
```

Wait 10 seconds, then test:
```bash
curl http://3.145.42.104:5000/api/health
```

## Quick Diagnostic Commands

**From your local machine:**
```bash
# Test health endpoint
curl http://3.145.42.104:5000/api/health

# Check if port is open (may require nmap)
nmap -p 5000 3.145.42.104
```

**From EC2 (via SSH):**
```bash
# Check container status
docker ps -a | grep al-chat-backend-staging

# Check port mapping
docker port al-chat-backend-staging

# Check logs
docker logs al-chat-backend-staging --tail 20

# Test locally
curl http://localhost:5000/api/health

# Check if port is listening
sudo netstat -tlnp | grep 5000
```

## Most Likely Issues

1. **Security Group not allowing port 5000** - Most common
2. **Container still using old port 5001** - Needs redeployment
3. **Container crashed** - Check logs and restart
4. **Container not started** - Start with `docker start al-chat-backend-staging`

## Solution Steps

1. **Verify Security Group allows port 5000**
2. **Redeploy if container is using port 5001:**
   ```bash
   ./scripts/deploy-to-staging.sh
   ```
3. **If still not working, restart container:**
   ```bash
   bash scripts/restart-staging.sh
   ```
