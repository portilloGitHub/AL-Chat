# Local Integration Testing Guide

## Overview

AL-Chat backend now fetches OpenAI credentials from Papita API when available, with fallback to local `.env` file for development.

## Setup

### 1. Start Papita Backend

```bash
cd "C:\Users\Alberto Portillo\Documents\WebPage"
npm start
# Or if using Docker:
# docker-compose up
```

**Verify:** Papita backend is running on `http://localhost:3000`

**Test credentials endpoint:**
```bash
curl http://localhost:3000/api/credentials/global/openai
```

### 2. Start AL-Chat Backend

```bash
cd "C:\Users\Alberto Portillo\Documents\AL Chat\Backend"
python main.py
```

**Verify:** AL-Chat backend is running on `http://localhost:5000`

**Test health endpoint:**
```bash
curl http://localhost:5000/api/health
```

### 3. Test Credential Fetching

**Check credential source:**
```bash
curl http://localhost:5000/api/openai/info
```

Look for `credential_source` in the response:
- `"papita_api"` - Successfully fetching from Papita API ✅
- `"local_env"` - Using local .env file (fallback)

## Testing Flow

### Test 1: With Papita API Running

1. Start Papita backend (port 3000)
2. Start AL-Chat backend (port 5000)
3. Check `/api/openai/info` - should show `credential_source: "papita_api"`
4. Test chat endpoint:
   ```bash
   curl -X POST http://localhost:5000/api/chat \
     -H "Content-Type: application/json" \
     -d '{"message": "Hello, test message"}'
   ```

### Test 2: Without Papita API (Fallback)

1. Stop Papita backend
2. Ensure AL-Chat backend has `.env` file with `OPENAI_API_KEY`
3. Restart AL-Chat backend
4. Check `/api/openai/info` - should show `credential_source: "local_env"`
5. Test chat endpoint (should still work)

### Test 3: Full Integration (Main Website)

1. Start Papita backend (port 3000)
2. Start AL-Chat backend (port 5000)
3. Start Papita frontend:
   ```bash
   cd "C:\Users\Alberto Portillo\Documents\WebPage\client"
   npm start
   ```
4. Open browser: `http://localhost:3000` (or whatever port Papita frontend uses)
5. Navigate to dashboard
6. Click "AL-Chat" project
7. ChatWindow should open and connect to AL-Chat backend
8. Send a test message - should work!

## Environment Variables

### AL-Chat Backend `.env`:

```env
# For local development (fallback)
OPENAI_API_KEY=sk-your-key-here

# Papita API URL (default: http://localhost:3000)
PAPITA_API_URL=http://localhost:3000

# Optional
OPENAI_MODEL=gpt-3.5-turbo
PORT=5000
FLASK_ENV=development
```

## Troubleshooting

### Issue: "Could not fetch credentials from Papita API"

**Cause:** Papita backend is not running or URL is incorrect.

**Solution:**
1. Verify Papita backend is running: `curl http://localhost:3000/api/health`
2. Check `PAPITA_API_URL` in AL-Chat `.env` file
3. AL-Chat will automatically fallback to local `.env` file

### Issue: "OPENAI_API_KEY not found"

**Cause:** Neither Papita API nor local `.env` has the key.

**Solution:**
1. Ensure Papita backend has credentials stored
2. OR add `OPENAI_API_KEY` to AL-Chat `Backend/.env` file

### Issue: Chat not working from main website

**Cause:** AL-Chat backend not running or wrong URL.

**Solution:**
1. Verify AL-Chat backend is running: `curl http://localhost:5000/api/health`
2. Check main website's `ChatWindow.js` - should point to `http://localhost:5000/api`
3. Check browser console for CORS errors

## Expected Behavior

✅ **With Papita API:** Credentials fetched from `http://localhost:3000/api/credentials/global/openai`  
✅ **Without Papita API:** Falls back to `Backend/.env` file  
✅ **Error handling:** Graceful fallback, no crashes  
✅ **Performance:** API fetch happens on-demand (lazy loading)

## Next Steps

After local testing works:
1. Deploy AL-Chat backend to staging EC2
2. Update `PAPITA_API_URL` to staging Papita backend URL
3. Test integration on staging
4. Deploy to production
