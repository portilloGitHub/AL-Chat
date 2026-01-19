# AL-Chat Backend - Staging Integration Guide

## Current Staging Configuration

**Backend URL:** `http://3.145.42.104:5000/api`

**Port Mapping:**
- **Internal (container):** Port 5000
- **External (EC2 host):** Port 5000

## Main Website Configuration

The main website needs to be configured to connect to the AL-Chat backend on staging.

### Option 1: Update Main Website Configuration (Recommended)

Configure the main website to use different API URLs based on environment:

**For Staging:**
```javascript
// In main website's environment config or ChatWindow component
const AL_CHAT_API_URL = process.env.REACT_APP_AL_CHAT_API_URL || 
  (process.env.NODE_ENV === 'production' 
    ? 'http://3.145.42.104:5000/api'  // Staging
    : 'http://localhost:5000/api');   // Local
```

**Environment Variables:**
- Local: `REACT_APP_AL_CHAT_API_URL=http://localhost:5000/api`
- Staging: `REACT_APP_AL_CHAT_API_URL=http://3.145.42.104:5000/api`

### Option 2: Change Staging Port to 5000

If you prefer to keep port 5000 for staging (to match local), update the deployment scripts:

**In `scripts/deploy-to-staging.sh` and `scripts/deploy-to-staging.ps1`:**
Change `-p 5001:5000` to `-p 5000:5000`

**In `docker-compose.staging.yml`:**
Change `"5001:5000"` to `"5000:5000"`

**Note:** Ensure no other service on EC2 is using port 5000.

## Health Check Endpoints

**Staging:**
- Health: `http://3.145.42.104:5000/api/health`
- Chat: `http://3.145.42.104:5000/api/chat`
- Session Start: `http://3.145.42.104:5000/api/session/start`

**Local:**
- Health: `http://localhost:5000/api/health`
- Chat: `http://localhost:5000/api/chat`
- Session Start: `http://localhost:5000/api/session/start`

## Testing the Connection

```bash
# Test staging health endpoint
curl http://3.145.42.104:5000/api/health

# Expected response:
# {"status":"healthy","timestamp":"...","openai_configured":true}
```

## Troubleshooting

**Error: "Sorry, I couldn't connect to the chat service. Please make sure the AL-Chat backend is running on port 5000."**

This means the main website cannot connect to the backend. Check:

1. **Backend is running:** Verify the container is running on EC2
2. **Security Group:** Ensure port 5000 is open in AWS Security Group
3. **URL Configuration:** Main website should use `http://3.145.42.104:5000/api`

**Check if backend is running:**
```bash
curl http://3.145.42.104:5000/api/health
```

If this returns a healthy response, the backend is running correctly - the issue is the main website's URL configuration.
