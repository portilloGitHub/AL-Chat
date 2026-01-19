# AL-Chat Dockerization & Deployment Plan

**Date:** January 17, 2026  
**Status:** Planning - Ready to Implement

## Objective

Dockerize AL-Chat backend and deploy it to staging/production following the same pattern as Papita backend, so users can access AL-Chat from the dashboard.

## Current State

### Papita Backend (Working)
- **Tech**: Node.js/Express
- **Port**: 3000
- **Docker**: ✅ Dockerized
- **Deployment**: ECR → EC2 (3.145.42.104:3000)
- **Status**: ✅ Deployed and working

### AL-Chat Backend (Needs Dockerization)
- **Tech**: Python/Flask
- **Port**: 5000
- **Location**: `C:\Users\Alberto Portillo\Documents\AL Chat\Backend`
- **Docker**: ❌ Not dockerized
- **Deployment**: ❌ Local only
- **Status**: ⏳ Ready for dockerization

---

## Recommended Architecture

### **Option: Separate Containers, Same EC2 (RECOMMENDED)**

**Benefits:**
- ✅ Independent scaling and updates
- ✅ Clear separation of concerns
- ✅ Follows existing Papita pattern
- ✅ Cost efficient (single EC2 instance)
- ✅ Simple networking

**Setup:**
- **Papita Backend**: Port 3000 (existing)
- **AL-Chat Backend**: Port 5000 (new)
- Both containers on same EC2 instance

---

## Implementation Plan

### **Phase 1: Dockerization**

#### **Files to Create:**
1. `Backend/Dockerfile`
   - Base: `python:3.11-slim` or `python:3.11-alpine`
   - Install dependencies from `requirements.txt`
   - Non-root user for security
   - Health check endpoint
   - Expose port 5000
   - Run `python main.py`

2. `Backend/.dockerignore`
   - Exclude unnecessary files (SessionLog, node_modules, etc.)

---

### **Phase 2: ECR Setup**

#### **Option: Separate Repository (RECOMMENDED)**
- **Repository Name**: `papita-al-chat` or `al-chat-backend`
- **Tags**: 
  - `staging` for staging
  - `latest` for production
- **Region**: `us-east-2` (same as Papita)
- **Account ID**: `542784561925` (same as Papita)

---

### **Phase 3: Deployment Scripts**

#### **Files to Create:**
1. `scripts/deploy-al-chat.sh`
   - Build Docker image
   - Authenticate with ECR
   - Tag image (staging/production)
   - Push to ECR

2. `scripts/deploy-al-chat-to-staging.sh`
   - SSH to EC2 staging
   - Authenticate with ECR
   - Pull AL-Chat image
   - Stop old container
   - Start new container on port 5000

---

### **Phase 4: EC2 Deployment**

#### **Configuration:**
- **Container Name**: `al-chat-backend`
- **Port**: `5000:5000`
- **Environment**: Use `~/.env` file (same as Papita)
- **Restart Policy**: `unless-stopped`

#### **Docker Run Command:**
```bash
docker run -d \
  --name al-chat-backend \
  -p 5000:5000 \
  --env-file ~/.env \
  --restart unless-stopped \
  542784561925.dkr.ecr.us-east-2.amazonaws.com/papita-al-chat:staging
```

---

## Environment Variables Needed

### **AL-Chat Backend (.env file on EC2):**
- `PAPITA_API_URL` - URL to Papita backend (for fetching credentials)
- `FLASK_ENV=production`
- Any other AL-Chat specific secrets

---

**Ready to implement!** 🚀
