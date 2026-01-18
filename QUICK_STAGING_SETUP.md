# Quick Staging Setup Checklist

## ✅ What We Have
- Docker configuration files (Dockerfile, docker-compose.staging.yml)
- Deployment scripts
- Staging branch created ✅

## 📋 Setup Checklist

### 1. Ensure Docker Desktop is Running (Windows)
- Open Docker Desktop application
- Wait until it shows "Docker Desktop is running"
- Verify: Open PowerShell and run: `docker ps`

### 2. Test Docker Build Locally (Before Staging)
```powershell
# Navigate to Backend directory
cd Backend

# Build Docker image locally (test)
docker build -t al-chat-backend:test .

# Test run (optional - replace YOUR_KEY with actual key for testing)
# docker run -p 5001:5000 -e OPENAI_API_KEY=YOUR_KEY al-chat-backend:test

# Test health endpoint (in another terminal):
# curl http://localhost:5001/api/health
```

### 3. Push to Staging Branch
```bash
# If not already on staging:
git checkout staging
git merge master  # Merge latest changes
git push origin staging
```

### 4. Deploy to Staging Server

**On your staging server (AWS EC2, etc.):**

```bash
# SSH into staging server
ssh user@your-staging-server

# Clone or update repository
cd /path/to/your/projects
git clone https://github.com/portilloGitHub/AL-Chat.git
# OR if already cloned:
cd AL-Chat
git checkout staging
git pull origin staging

# Create staging logs directory
mkdir -p SessionLog/staging

# Option 1: Use deployment script
./deploy/staging-deploy.sh

# Option 2: Manual deployment
docker-compose -f docker-compose.staging.yml build
docker-compose -f docker-compose.staging.yml up -d
```

### 5. Verify Deployment
```bash
# Check container status
docker ps | grep al-chat-backend-staging

# Test health endpoint
curl http://localhost:5001/api/health

# View logs
docker-compose -f docker-compose.staging.yml logs -f
```

## 🚀 Quick Commands

```bash
# Start staging
docker-compose -f docker-compose.staging.yml up -d

# Stop staging
docker-compose -f docker-compose.staging.yml down

# View logs
docker-compose -f docker-compose.staging.yml logs -f

# Rebuild after code changes
docker-compose -f docker-compose.staging.yml up -d --build
```

## ⚠️ Important Notes

1. **OpenAI API Key**: Set `OPENAI_API_KEY` in environment variables or `.env.staging` file
2. **Port**: Staging uses port **5001** (different from local dev port 5000)
3. **Staging Branch**: Always deploy from `staging` branch, not `master`
4. **Main Website**: When integrated, staging will be accessible via main website's reverse proxy

## 📝 Environment Variables

For staging, you can set environment variables:

**Option 1: In docker-compose.staging.yml**
```yaml
environment:
  - OPENAI_API_KEY=sk-your-key-here
```

**Option 2: Using .env file (recommended)**
```bash
# Create .env.staging (don't commit to git!)
echo "OPENAI_API_KEY=sk-your-key-here" > .env.staging
docker-compose -f docker-compose.staging.yml --env-file .env.staging up -d
```

## 🔗 Integration with Main Website

When ready to integrate with main website:

1. Add AL-Chat service to main website's `docker-compose.staging.yml`
2. Configure reverse proxy: `/api/al-chat/*` → `al-chat-backend-staging:5000`
3. Main website deployment will automatically deploy AL-Chat
