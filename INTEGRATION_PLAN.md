# AL-Chat Integration Plan

## 🎯 Goals

1. **Main page as portal** - Entry point for all projects (AL-Chat, AI Resume, etc.)
2. **Centralized credentials** - Single place for OpenAI tokens (and future projects)
3. **Dashboard launch** - User selects AL-Chat from dashboard and it runs
4. **Standalone AL-Chat** - Dockerized, can be updated independently

---

## 📋 Implementation Plan

### **Phase 1: Centralized Credentials System** ✅ COMPLETE

#### **Step 1.1: Database Schema** ✅
Created `credentials` table in Papita database to store OpenAI API keys (and future project credentials).

#### **Step 1.2: API Endpoints** ✅
Created credentials API in Papita backend:
- `GET /api/credentials` - Get credentials for user
- `POST /api/credentials` - Store credentials
- `PUT /api/credentials/:id` - Update credentials
- `DELETE /api/credentials/:id` - Delete credentials

#### **Step 1.3: Repository Layer** ✅
Created `repositories/credentialsRepository.js` for database operations.

**Status:** ✅ **Phase 1 Complete** - Credentials system is ready in Papita backend.

---

### **Phase 2: AL-Chat Integration** 🔄 IN PROGRESS

#### **Step 2.1: Update AL-Chat Credential Manager** ⏳ TODO
**Current:** AL-Chat has its own credential manager/storage  
**Change:** Fetch credentials from Papita API (`http://localhost:3000/api/credentials`)

**Files to modify:**
- `Backend/credentials/credential_manager.py` (or similar)
- `Backend/service/openai_service.py` (or wherever OpenAI API key is used)

**Changes needed:**
- Remove local credential storage/loading
- Add function to fetch credentials from Papita API
- Pass username/userId to fetch credentials
- Handle credential fetching errors gracefully

#### **Step 2.2: Update AL-Chat API Endpoints** ⏳ TODO
**Current:** AL-Chat backend runs independently  
**Change:** Accept username/userId to fetch credentials

**Option A (Recommended):** AL-Chat backend calls Papita API directly
- AL-Chat receives username from frontend
- AL-Chat calls `GET http://localhost:3000/api/credentials?username=X&credentialType=openai&projectId=al-chat`
- Uses credentials for OpenAI calls

#### **Step 2.3: Environment Configuration** ⏳ TODO
Add Papita API URL configuration:
- `PAPITA_API_URL` environment variable (default: `http://localhost:3000`)
- Or configurable via config file

---

### **Phase 3: Dockerization** ⏳ TODO

#### **Step 3.1: Create Dockerfile**
- `Backend/Dockerfile`
- `Backend/.dockerignore`

#### **Step 3.2: Update AL-Chat to Use Centralized Credentials**
- Remove local credential manager
- Call main API for credentials

---

### **Phase 4: Frontend Integration** ⏳ TODO

#### **Step 4.1: Update UserDashboard**
Implement `handleProjectClick` to launch AL-Chat:
- Check if AL-Chat backend is running
- Open ChatWindow with proper configuration
- Pass username to AL-Chat backend

#### **Step 4.2: Update ChatWindow**
- Pass username to AL-Chat backend
- AL-Chat fetches credentials from Papita API

---

## 🔐 Security Considerations

1. **Encryption**: Store credentials encrypted in database (future enhancement)
2. **User isolation**: Users can only access their own credentials
3. **API authentication**: Require valid user session for credential access
4. **No local storage**: Remove credentials from localStorage/browser

---

## 🚀 Testing Workflow

1. **Setup database** - Run credentials migration (already done in Papita)
2. **Store credentials** - Admin/user stores OpenAI key via Papita API
3. **Update AL-Chat** - Modify AL-Chat to fetch credentials from API
4. **Test locally** - Start Papita backend, AL-Chat backend, verify credentials flow
5. **Launch AL-Chat** - From dashboard, click AL-Chat
6. **Test chat** - Verify AL-Chat can use credentials from API

---

## 📝 Example Code Changes

### **Before (Local Credential Loading):**
```python
# credential_manager.py
def get_openai_key():
    return os.getenv('OPENAI_API_KEY') or load_from_file()
```

### **After (API Credential Fetching):**
```python
# credential_manager.py
import requests

PAPITA_API_URL = os.getenv('PAPITA_API_URL', 'http://localhost:3000')

def get_openai_key(username):
    try:
        response = requests.get(
            f'{PAPITA_API_URL}/api/credentials',
            params={
                'username': username,
                'credentialType': 'openai',
                'projectId': 'al-chat'
            }
        )
        if response.status_code == 200:
            data = response.json()
            return data['credentials']['credentials'].get('api_key')
        return None
    except Exception as e:
        print(f'Error fetching credentials: {e}')
        return None
```

---

**Ready to update AL-Chat!** 🚀
