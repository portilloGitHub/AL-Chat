# Step 1: Review Current AL-Chat Structure ✅

## 📋 Current Credential Flow

### **1. Credential Manager** (`Backend/credentials/credential_manager.py`)

**Current Implementation:**
- Loads credentials from `.env` file in Backend directory
- Uses `os.getenv('OPENAI_API_KEY')` to get API key
- No username/userId support
- Validates credentials on initialization

**Key Methods:**
- `get_openai_api_key()` - Returns API key from environment
- `get_openai_model()` - Returns model name (default: gpt-3.5-turbo)
- `validate_openai_credentials()` - Validates API key format

**Current Flow:**
```python
CredentialManager() → loads .env → get_openai_api_key() → returns API key
```

---

### **2. OpenAI Service** (`Backend/service/openai_service.py`)

**Current Implementation:**
- Takes `CredentialManager` instance in constructor
- Uses `credential_manager.get_openai_api_key()` to initialize OpenAI client
- Creates OpenAI client at initialization time
- No username/userId support

**Key Methods:**
- `send_message()` - Sends message to OpenAI API
- `test_connection()` - Tests OpenAI connection
- Uses global credential manager instance

**Current Flow:**
```python
OpenAIService(credential_manager) → gets API key → creates OpenAI client → ready to use
```

---

### **3. Main Flask App** (`Backend/main.py`)

**Current Implementation:**
- Creates **global** `CredentialManager()` instance at startup (line 51)
- Creates **global** `OpenAIService(credential_manager)` instance at startup (line 57)
- All endpoints use the global `openai_service` instance
- No username/userId handling in requests

**Key Endpoints:**
- `POST /api/chat` - Uses global `openai_service` (line 139)
- `GET /api/health` - Health check
- `POST /api/session/start` - Starts session (no username)
- `POST /api/session/stop` - Stops session

**Current Flow:**
```python
App starts → creates global CredentialManager → creates global OpenAIService → 
all requests use same global service
```

---

## 🔍 Key Findings

### **What Works:**
✅ Credential manager is well-structured  
✅ OpenAI service is properly abstracted  
✅ Error handling exists  
✅ Requirements.txt has `httpx` (can use for API calls)

### **What Needs to Change:**
❌ Credentials loaded from `.env` file (need to fetch from API)  
❌ No username/userId support  
❌ Global credential manager (need per-request credentials)  
❌ No Papita API integration  

---

## 📝 Changes Needed

### **Change 1: Update CredentialManager**
- Add method to fetch credentials from Papita API
- Accept username parameter
- Keep `.env` as fallback (for backward compatibility)

### **Change 2: Update OpenAI Service**
- Support dynamic credential fetching (not just at initialization)
- Accept username for credential lookup

### **Change 3: Update Main Flask App**
- Accept username in requests (from frontend)
- Fetch credentials per request (or cache per user)
- Pass username to credential manager

---

## 🎯 Next Steps

**Step 2:** Add Papita API client to CredentialManager  
**Step 3:** Update credential loading to use API  
**Step 4:** Update main.py to accept username in requests  
**Step 5:** Test locally  

---

**Step 1 Complete!** ✅ Ready to proceed to Step 2.
