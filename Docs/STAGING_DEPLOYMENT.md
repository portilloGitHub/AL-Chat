# AL-Chat Staging Deployment Guide

This guide describes the staging deployment process for AL-Chat, designed to match the main website's deployment workflow.

## Overview

AL-Chat follows a branch-based deployment strategy:
1. **Local Development**: Work on `master` branch
2. **Staging**: Push to `staging` branch → Deploy to staging environment
3. **Production**: Merge `staging` → `master` → Deploy to production

## Prerequisites

- Docker and Docker Compose installed
- Access to staging environment (AWS EC2 or similar)
- Git repository with `staging` branch
- Environment variables configured for staging

## Staging Deployment Process

### 1. Prepare Changes

Ensure all changes are committed to `master`:

```bash
# Review changes
git status

# Commit any pending changes
git add .
git commit -m "Your commit message"

# Push to master
git push origin master
```

### 2. Push to Staging Branch

```bash
# Switch to staging branch (or create it)
git checkout staging
# OR if staging doesn't exist:
# git checkout -b staging

# Merge master into staging
git merge master

# Push staging branch
git push origin staging
```

### 3. Deploy to Staging Environment

#### Option A: Automated Deployment (Recommended)

If your main website has CI/CD configured:

1. Push to `staging` branch triggers automatic deployment
2. Deployment script runs on staging server
3. Docker containers are rebuilt and restarted

#### Option B: Manual Deployment

**On Staging Server:**

```bash
# SSH into staging server
ssh user@staging-server

# Navigate to AL-Chat directory (or clone/update)
cd /path/to/AL-Chat

# Pull latest staging branch
git checkout staging
git pull origin staging

# Deploy using deployment script
# Linux/Mac:
./deploy/staging-deploy.sh

# Windows (PowerShell):
.\deploy\staging-deploy.ps1

# Or manually:
docker-compose -f docker-compose.staging.yml build
docker-compose -f docker-compose.staging.yml up -d
```

### 4. Verify Staging Deployment

```bash
# Check container status
docker-compose -f docker-compose.staging.yml ps

# Check logs
docker-compose -f docker-compose.staging.yml logs -f al-chat-backend

# Test health endpoint
curl http://localhost:5001/api/health
# OR from browser: http://staging-server:5001/api/health
```

## Integration with Main Website

When AL-Chat is integrated into the main website's Docker setup:

### Main Website's docker-compose.staging.yml

Add AL-Chat as a service:

```yaml
services:
  # ... existing services ...
  
  al-chat-backend:
    build:
      context: ./path/to/AL-Chat/Backend
      dockerfile: Dockerfile
    container_name: al-chat-backend-staging
    environment:
      - FLASK_ENV=staging
      - DEPLOYMENT_MODE=staging
      # OpenAI API key from main site's auth in production
    networks:
      - main-website-staging-network
    restart: unless-stopped
    labels:
      - "environment=staging"
```

### Deployment Workflow

1. **Main Website Staging Deploy**: Triggers deployment of all services
2. **AL-Chat Included**: AL-Chat container is rebuilt and started
3. **Network Integration**: AL-Chat accessible via main site's reverse proxy
4. **Health Checks**: Main site monitors AL-Chat health

## Environment Configuration

### Staging Environment Variables

Create `.env.staging` file (or set in docker-compose.staging.yml):

```bash
# .env.staging
OPENAI_API_KEY=sk-your-staging-key-here  # For local testing
OPENAI_MODEL=gpt-3.5-turbo
FLASK_ENV=staging
PORT=5000
AL_CHAT_LOG_DIR=/app/SessionLog
DEPLOYMENT_MODE=staging
```

### Loading Environment Variables

```bash
# Using .env file
docker-compose -f docker-compose.staging.yml --env-file .env.staging up -d

# Or set in docker-compose.staging.yml directly
```

## Staging URLs and Ports

- **Staging Backend**: `http://staging-server:5001/api`
- **Health Check**: `http://staging-server:5001/api/health`
- **Via Main Site Proxy**: `https://staging.yourdomain.com/api/al-chat/*`

## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker-compose -f docker-compose.staging.yml logs al-chat-backend

# Check container status
docker ps -a | grep al-chat

# Restart container
docker-compose -f docker-compose.staging.yml restart al-chat-backend
```

### Health Check Failing

```bash
# Test health endpoint directly
curl http://localhost:5001/api/health

# Check if port is accessible
netstat -tuln | grep 5001  # Linux
netstat -an | findstr 5001  # Windows
```

### Build Errors

```bash
# Rebuild without cache
docker-compose -f docker-compose.staging.yml build --no-cache

# Check Dockerfile syntax
docker build -t test-build ./Backend
```

## Updating Staging

To update staging after pushing changes:

```bash
# On staging server
git pull origin staging
docker-compose -f docker-compose.staging.yml up -d --build
```

## Rolling Back Staging

```bash
# Revert to previous commit
git checkout <previous-commit-hash>
docker-compose -f docker-compose.staging.yml up -d --build

# Or revert git merge
git revert HEAD
git push origin staging
```

## Production Deployment

Once staging is verified:

1. Merge staging → master:
   ```bash
   git checkout master
   git merge staging
   git push origin master
   ```

2. Deploy to production using `docker-compose.production.yml` or main website's production deployment

See `Docs/INTEGRATION_REVIEW.md` for production integration details.

## Monitoring

### View Logs

```bash
# Follow logs
docker-compose -f docker-compose.staging.yml logs -f al-chat-backend

# Last 100 lines
docker-compose -f docker-compose.staging.yml logs --tail=100 al-chat-backend
```

### Resource Usage

```bash
# Container stats
docker stats al-chat-backend-staging

# Disk usage
docker system df
```

## Best Practices

1. **Always test locally first** before pushing to staging
2. **Review changes** in staging before promoting to production
3. **Monitor logs** after deployment
4. **Keep staging environment** as close to production as possible
5. **Use version tags** for Docker images in production
6. **Document changes** in commit messages

## Next Steps

- Set up CI/CD pipeline for automatic staging deployments
- Configure monitoring and alerting for staging environment
- Set up database for staging (if needed)
- Configure SSL/TLS certificates for staging domain
