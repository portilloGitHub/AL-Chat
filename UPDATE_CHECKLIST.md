# AL-Chat Update Checklist

## 🎯 Goal
Update AL-Chat to use centralized credentials from the main Papita API instead of local credential storage.

---

## 📋 What Needs to Change in AL-Chat

### **1. Credential Management** ⏳ TODO
**Current:** AL-Chat likely has its own credential manager/storage  
**Change:** Fetch credentials from Papita API (`http://localhost:3000/api/credentials`)

**Files to check/modify:**
- `Backend/credentials/credential_manager.py` (or similar)
- `Backend/service/openai_service.py` (or wherever OpenAI API key is used)

**Changes needed:**
- Remove local credential storage/loading
- Add function to fetch credentials from Papita API
- Pass username/userId to fetch credentials
- Handle credential fetching errors gracefully

---

### **2. API Endpoint Updates** ⏳ TODO
**Current:** AL-Chat backend runs independently  
**Change:** Accept username/userId to fetch credentials

**Options:**
- **Option A:** AL-Chat backend calls Papita API directly (RECOMMENDED)
  - AL-Chat receives username from frontend
  - AL-Chat calls `GET http://localhost:3000/api/credentials?username=X&credentialType=openai&projectId=al-chat`
  - Uses credentials for OpenAI calls

- **Option B:** Frontend fetches credentials and passes to AL-Chat
  - Frontend calls Papita API to get credentials
  - Frontend passes credentials to AL-Chat backend
  - AL-Chat uses provided credentials

**Recommendation:** Option A (AL-Chat fetches from API) - more secure, credentials don't pass through frontend

---

### **3. Environment Configuration** ⏳ TODO
**Current:** May use environment variables or local config  
**Change:** Add Papita API URL configuration

**Add to AL-Chat:**
- `PAPITA_API_URL` environment variable (default: `http://localhost:3000`)
- Or configurable via config file

---

### **4. Error Handling** ⏳ TODO
**Changes needed:**
- Handle case where credentials don't exist
- Handle case where Papita API is unavailable
- Provide clear error messages to user

---

## ✅ Update Steps

### **Step 1: Review Current AL-Chat Structure** ⏳ TODO
- Check how credentials are currently stored/loaded
- Identify where OpenAI API key is used
- Understand the current credential flow

### **Step 2: Add Papita API Client** ⏳ TODO
- Create function to fetch credentials from Papita API
- Add error handling for API failures
- Add retry logic if needed

### **Step 3: Update Credential Loading** ⏳ TODO
- Replace local credential loading with API call
- Pass username/userId to credential fetch function
- Cache credentials (optional, for performance)

### **Step 4: Update OpenAI Service** ⏳ TODO
- Use credentials from API instead of local storage
- Handle missing credentials gracefully

### **Step 5: Test Locally** ⏳ TODO
- Start Papita backend (port 3000)
- Store test credentials via API
- Start AL-Chat backend (port 5000)
- Verify AL-Chat can fetch and use credentials

---

## 🔐 Security Considerations

1. **Credentials in transit:** Use HTTPS in production
2. **API authentication:** May need to add auth token for API calls (future)
3. **Credential caching:** Don't log credentials, clear from memory when done
4. **Error messages:** Don't expose credential values in errors

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

**Ready to update AL-Chat!** 🔍
