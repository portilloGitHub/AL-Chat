# Test Suite

Test scripts for verifying backend functionality.

## ⚠️ Important Rule

**All test-related items MUST be placed in the `Test/` folder.**

See [TEST_RULES.md](TEST_RULES.md) for complete rules and guidelines.

## Test Scripts

### 1. `test_backend.py` - Full Backend API Tests
Tests all API endpoints via HTTP requests.

**Usage:**
```bash
# Make sure backend is running first
cd Backend
python main.py

# In another terminal
cd Test
python test_backend.py
```

**Tests:**
- Health check endpoint
- OpenAI info endpoint
- OpenAI connection test
- Session start/stop
- Chat endpoint

### 2. `test_credentials.py` - Credential Manager Tests
Tests credential loading and validation directly.

**Usage:**
```bash
cd Test
python test_credentials.py
```

**Tests:**
- CredentialManager initialization
- Credential validation
- .env file detection

### 3. `test_openai_service.py` - OpenAI Service Tests
Tests OpenAI service directly (without Flask server).

**Usage:**
```bash
cd Test
python test_openai_service.py
```

**Requirements:**
- Backend/.env file with OPENAI_API_KEY

**Tests:**
- Service initialization
- Connection test
- Message sending

## Running All Tests

### Quick Test (Backend Running)
```bash
python test_backend.py
```

### Full Test Suite
```bash
# Test credentials
python test_credentials.py

# Test OpenAI service (requires .env)
python test_openai_service.py

# Test API endpoints (requires backend running)
python test_backend.py
```

## Requirements

Install test dependencies:
```bash
pip install requests
```

Or install all backend dependencies:
```bash
cd Backend
pip install -r requirements.txt
```
