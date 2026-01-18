# AL-Chat Deployment Workflow

Quick reference for deploying AL-Chat to staging and production.

## Branch Strategy

```
master (local dev) → staging (staging environment) → master (production)
```

## Local Development

```bash
# Work on master branch
git checkout master
git pull origin master

# Make changes, test locally
docker-compose up --build

# Commit changes
git add .
git commit -m "Your changes"
git push origin master
```

## Staging Deployment

### 1. Push to Staging Branch

```bash
# Switch to staging branch
git checkout staging
git merge master

# Push to staging
git push origin staging
```

### 2. Deploy to Staging

**On Staging Server:**

```bash
# Pull latest changes
git checkout staging
git pull origin staging

# Deploy (choose one):
# Linux/Mac:
./deploy/staging-deploy.sh

# Windows (PowerShell):
.\deploy\staging-deploy.ps1

# Or manually:
docker-compose -f docker-compose.staging.yml build
docker-compose -f docker-compose.staging.yml up -d
```

### 3. Verify Staging

```bash
# Check health
curl http://localhost:5001/api/health

# View logs
docker-compose -f docker-compose.staging.yml logs -f
```

## Production Deployment

### 1. Merge Staging to Master

```bash
# After staging is verified, merge to master
git checkout master
git merge staging
git push origin master
```

### 2. Deploy to Production

**On Production Server:**

```bash
# Pull latest changes
git checkout master
git pull origin master

# Deploy using main website's docker-compose (integrated)
# OR if standalone:
docker-compose -f docker-compose.production.yml build
docker-compose -f docker-compose.production.yml up -d
```

## Integration with Main Website

When AL-Chat is integrated into main website:

1. **Main website's docker-compose.staging.yml** includes AL-Chat service
2. **Deploy main website staging** → AL-Chat deploys automatically
3. **AL-Chat accessible via**: `https://staging.yourdomain.com/api/al-chat/*`

## Quick Commands

```bash
# Local development
docker-compose up --build

# Staging deployment
docker-compose -f docker-compose.staging.yml up -d --build

# Production deployment (via main website)
# Use main website's deployment process

# View logs
docker-compose -f docker-compose.staging.yml logs -f al-chat-backend

# Stop staging
docker-compose -f docker-compose.staging.yml down

# Restart staging
docker-compose -f docker-compose.staging.yml restart
```

## Troubleshooting

```bash
# Check container status
docker-compose -f docker-compose.staging.yml ps

# Check health
curl http://localhost:5001/api/health

# View recent logs
docker-compose -f docker-compose.staging.yml logs --tail=100 al-chat-backend

# Rebuild without cache
docker-compose -f docker-compose.staging.yml build --no-cache
```

## Environment Files

- **Local**: Use `docker-compose.yml` (default port 5000)
- **Staging**: Use `docker-compose.staging.yml` (port 5001)
- **Production**: Use `docker-compose.production.yml` (internal network only)

## Documentation

- Full staging guide: `Docs/STAGING_DEPLOYMENT.md`
- Docker setup: `Docker.md`
- Integration: `Docs/INTEGRATION_REVIEW.md`
