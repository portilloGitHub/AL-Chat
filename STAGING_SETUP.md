# Staging Environment Setup Guide

Step-by-step guide to set up AL-Chat staging environment.

## Current Status

✅ **What we have:**
- Docker configuration files (`Dockerfile`, `docker-compose.staging.yml`)
- Deployment scripts
- Documentation

❌ **What we need to do:**
- Test Docker build locally first
- Set up staging branch (if not exists)
- Build Docker images for staging
- Deploy to staging server

## Step-by-Step Setup

### Step 1: Test Docker Build Locally (Recommended)

Before deploying to staging, test the Docker build on your local machine:

```bash
# Test building the backend Docker image
cd Backend
docker build -t al-chat-backend:test .

# Test running the container locally
docker run -p 5001:5000 -e OPENAI_API_KEY=your-key-here al-chat-backend:test

# In another terminal, test health endpoint
curl http://localhost:5001/api/health

# Stop the test container
docker ps  # Note the container ID
docker stop <container-id>
```

### Step 2: Set Up Staging Branch

```bash
# Check if staging branch exists
git branch -a

# If staging doesn't exist, create it:
git checkout -b staging
git push origin staging

# If staging exists, switch to it:
git checkout staging
git merge master  # Merge latest changes
git push origin staging
```

### Step 3: Prepare Staging Server

**If staging server is remote (AWS EC2, etc.):**

1. **SSH into staging server:**
   ```bash
   ssh user@staging-server-ip
   ```

2. **Install prerequisites (if not installed):**
   ```bash
   # Docker (if not installed)
   sudo apt-get update
   sudo apt-get install -y docker.io docker-compose
   sudo systemctl start docker
   sudo systemctl enable docker
   
   # Git (if not installed)
   sudo apt-get install -y git
   ```

3. **Clone or update AL-Chat repository:**
   ```bash
   # If first time - clone
   git clone https://github.com/portilloGitHub/AL-Chat.git
   cd AL-Chat
   
   # If already cloned - update
   cd /path/to/AL-Chat
   git checkout staging
   git pull origin staging
   ```

4. **Create staging logs directory:**
   ```bash
   mkdir -p SessionLog/staging
   ```

### Step 4: Configure Environment Variables (Optional)

**Option A: Use environment variables directly in docker-compose**

Edit `docker-compose.staging.yml` and add your OPENAI_API_KEY:
```yaml
environment:
  - OPENAI_API_KEY=sk-your-actual-key-here
```

**Option B: Use .env file (more secure)**

```bash
# Create .env.staging file
cat > .env.staging << EOF
OPENAI_API_KEY=sk-your-actual-key-here
OPENAI_MODEL=gpt-3.5-turbo
FLASK_ENV=staging
EOF

# Make sure it's not committed to git (should be in .gitignore)
```

Then load it:
```bash
docker-compose -f docker-compose.staging.yml --env-file .env.staging up -d
```

### Step 5: Deploy to Staging

**Option A: Use deployment script (recommended):**

```bash
# Linux/Mac
./deploy/staging-deploy.sh

# Windows PowerShell
.\deploy\staging-deploy.ps1
```

**Option B: Manual deployment:**

```bash
# Build and start staging containers
docker-compose -f docker-compose.staging.yml build
docker-compose -f docker-compose.staging.yml up -d

# Check status
docker-compose -f docker-compose.staging.yml ps

# View logs
docker-compose -f docker-compose.staging.yml logs -f
```

### Step 6: Verify Staging Deployment

```bash
# Check container is running
docker ps | grep al-chat-backend-staging

# Test health endpoint
curl http://localhost:5001/api/health

# Or from your local machine (if port is exposed):
curl http://staging-server-ip:5001/api/health
```

## Troubleshooting

### Build fails

```bash
# Check Dockerfile syntax
cd Backend
docker build -t test-build .

# Check for errors in logs
docker-compose -f docker-compose.staging.yml build --no-cache
```

### Container won't start

```bash
# Check logs
docker-compose -f docker-compose.staging.yml logs al-chat-backend

# Check if port 5001 is already in use
netstat -tuln | grep 5001  # Linux
netstat -an | findstr 5001  # Windows
```

### Health check failing

```bash
# Check if backend is responding
docker exec al-chat-backend-staging curl http://localhost:5000/api/health

# Check environment variables
docker exec al-chat-backend-staging env | grep OPENAI
```

## Next Steps After Staging is Working

1. **Test AL-Chat functionality** in staging environment
2. **Configure main website integration** (if ready)
3. **Set up monitoring** and logging
4. **Prepare for production deployment**

## Integration with Main Website

When staging is verified, integrate with main website:

1. Add AL-Chat service to main website's `docker-compose.staging.yml`
2. Configure reverse proxy to route `/api/al-chat/*` to AL-Chat backend
3. Test end-to-end integration

## Quick Commands Reference

```bash
# Start staging
docker-compose -f docker-compose.staging.yml up -d

# Stop staging
docker-compose -f docker-compose.staging.yml down

# View logs
docker-compose -f docker-compose.staging.yml logs -f

# Restart staging
docker-compose -f docker-compose.staging.yml restart

# Rebuild after code changes
docker-compose -f docker-compose.staging.yml up -d --build
```
