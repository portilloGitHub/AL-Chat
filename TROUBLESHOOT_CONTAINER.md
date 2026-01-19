# Troubleshooting Container Issues

## Connection Reset Error

If you get: `curl: (56) Recv failure: Connection reset by peer`

This means the container is running but the application inside is failing.

## Diagnostic Commands

Run these on EC2:

```bash
# 1. Check if container is actually running
docker ps -a | grep al-chat-backend-staging

# 2. Check container logs (most important!)
docker logs al-chat-backend-staging

# 3. Check if port is bound correctly
sudo netstat -tulpn | grep 5001
# OR
sudo ss -tulpn | grep 5001

# 4. Check container status in detail
docker inspect al-chat-backend-staging | grep -i status -A 5

# 5. If container keeps restarting, check restart count
docker ps -a | grep al-chat-backend-staging
```

## Common Issues

### 1. Container Exited Immediately

**Check logs:**
```bash
docker logs al-chat-backend-staging
```

**Common causes:**
- Missing `.env-al-chat` file
- Invalid environment variables
- Python application error
- Missing dependencies

### 2. Environment File Issues

**Check if .env-al-chat exists:**
```bash
cat ~/.env-al-chat
```

**If missing, create it:**
```bash
nano ~/.env-al-chat
```

Add:
```
OPENAI_API_KEY=sk-your-key-here
OPENAI_MODEL=gpt-3.5-turbo
FLASK_ENV=staging
PORT=5000
DEPLOYMENT_MODE=staging
```

### 3. Backend Application Error

**Check full logs:**
```bash
docker logs al-chat-backend-staging --tail 100
```

Look for Python errors or import errors.

### 4. Port Not Binding

**Check if backend is listening:**
```bash
# From inside the container
docker exec al-chat-backend-staging netstat -tulpn | grep 5000

# Or check what the container is actually doing
docker exec al-chat-backend-staging ps aux
```

## Quick Fix Steps

1. **Stop container:**
```bash
docker stop al-chat-backend-staging
docker rm al-chat-backend-staging
```

2. **Check logs from previous run:**
```bash
# If container was removed, logs might be gone
# Check if there's a way to see recent failures
```

3. **Start with logs visible:**
```bash
docker run --name al-chat-backend-staging-test \
  -p 5001:5000 \
  --env-file ~/.env-al-chat \
  542784561925.dkr.ecr.us-east-2.amazonaws.com/al-chat-backend:staging

# Watch logs in real-time (Ctrl+C to stop)
docker logs -f al-chat-backend-staging-test
```

4. **Once working, restart properly:**
```bash
docker stop al-chat-backend-staging-test
docker rm al-chat-backend-staging-test

docker run -d \
  --name al-chat-backend-staging \
  -p 5001:5000 \
  --env-file ~/.env-al-chat \
  --restart unless-stopped \
  542784561925.dkr.ecr.us-east-2.amazonaws.com/al-chat-backend:staging
```
