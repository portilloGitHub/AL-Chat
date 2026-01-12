"""
Backend Test Script
Tests the backend API endpoints
"""
import requests
import json
import sys
from datetime import datetime

# Base URL for the backend
BASE_URL = "http://localhost:5000/api"

def print_section(title):
    """Print a formatted section header"""
    print("\n" + "="*60)
    print(f"  {title}")
    print("="*60)

def test_health_check():
    """Test the health check endpoint"""
    print_section("Testing Health Check")
    try:
        response = requests.get(f"{BASE_URL}/health")
        print(f"Status Code: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
        return response.status_code == 200
    except requests.exceptions.ConnectionError:
        print("❌ ERROR: Cannot connect to backend. Is the server running?")
        print("   Start the server with: cd Backend && python main.py")
        return False
    except Exception as e:
        print(f"❌ ERROR: {str(e)}")
        return False

def test_openai_info():
    """Test OpenAI info endpoint"""
    print_section("Testing OpenAI Info")
    try:
        response = requests.get(f"{BASE_URL}/openai/info")
        print(f"Status Code: {response.status_code}")
        data = response.json()
        print(f"Response: {json.dumps(data, indent=2)}")
        
        if "error" in data:
            print("\n⚠️  OpenAI not configured. You need to:")
            print("   1. Create Backend/.env file")
            print("   2. Add OPENAI_API_KEY=your_key_here")
            return False
        return True
    except Exception as e:
        print(f"❌ ERROR: {str(e)}")
        return False

def test_openai_connection():
    """Test OpenAI connection"""
    print_section("Testing OpenAI Connection")
    try:
        response = requests.get(f"{BASE_URL}/openai/test")
        print(f"Status Code: {response.status_code}")
        data = response.json()
        print(f"Response: {json.dumps(data, indent=2)}")
        
        if data.get("status") == "success":
            print("\n✅ OpenAI connection successful!")
            return True
        else:
            print("\n❌ OpenAI connection failed")
            return False
    except Exception as e:
        print(f"❌ ERROR: {str(e)}")
        return False

def test_session_start():
    """Test session start endpoint"""
    print_section("Testing Session Start")
    try:
        response = requests.post(f"{BASE_URL}/session/start")
        print(f"Status Code: {response.status_code}")
        data = response.json()
        print(f"Response: {json.dumps(data, indent=2)}")
        
        if "session_id" in data:
            print(f"\n✅ Session started: {data['session_id']}")
            return data["session_id"]
        return None
    except Exception as e:
        print(f"❌ ERROR: {str(e)}")
        return None

def test_session_stop(session_id):
    """Test session stop endpoint"""
    print_section("Testing Session Stop")
    try:
        payload = {
            "session_id": session_id,
            "metrics": {
                "messages_sent": 0,
                "messages_received": 0,
                "test": True
            }
        }
        response = requests.post(f"{BASE_URL}/session/stop", json=payload)
        print(f"Status Code: {response.status_code}")
        data = response.json()
        print(f"Response: {json.dumps(data, indent=2)}")
        return response.status_code == 200
    except Exception as e:
        print(f"❌ ERROR: {str(e)}")
        return False

def test_chat(message="Hello, this is a test message"):
    """Test chat endpoint"""
    print_section(f"Testing Chat: '{message}'")
    try:
        payload = {
            "message": message,
            "history": []
        }
        response = requests.post(f"{BASE_URL}/chat", json=payload)
        print(f"Status Code: {response.status_code}")
        data = response.json()
        
        if response.status_code == 200:
            print(f"✅ Chat Response: {data.get('message', 'No message')}")
            print(f"Timestamp: {data.get('timestamp', 'N/A')}")
            return True
        else:
            print(f"❌ Error: {data.get('error', 'Unknown error')}")
            return False
    except Exception as e:
        print(f"❌ ERROR: {str(e)}")
        return False

def main():
    """Run all tests"""
    print("\n" + "="*60)
    print("  AL-Chat Backend Test Suite")
    print(f"  Started: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("="*60)
    
    results = {
        "health_check": False,
        "openai_info": False,
        "openai_connection": False,
        "session_start": False,
        "session_stop": False,
        "chat": False
    }
    
    # Test 1: Health Check
    results["health_check"] = test_health_check()
    if not results["health_check"]:
        print("\n❌ Backend server is not running. Please start it first.")
        sys.exit(1)
    
    # Test 2: OpenAI Info
    results["openai_info"] = test_openai_info()
    
    # Test 3: OpenAI Connection (only if configured)
    if results["openai_info"]:
        results["openai_connection"] = test_openai_connection()
    
    # Test 4: Session Start
    session_id = test_session_start()
    results["session_start"] = session_id is not None
    
    # Test 5: Session Stop
    if session_id:
        results["session_stop"] = test_session_stop(session_id)
    
    # Test 6: Chat (only if OpenAI is configured)
    if results["openai_connection"]:
        results["chat"] = test_chat()
    else:
        print_section("Skipping Chat Test")
        print("⚠️  Chat test skipped - OpenAI not configured")
    
    # Summary
    print_section("Test Summary")
    total = len(results)
    passed = sum(1 for v in results.values() if v)
    
    for test_name, result in results.items():
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"  {test_name:20s} {status}")
    
    print(f"\n  Total: {passed}/{total} tests passed")
    
    if passed == total:
        print("\n🎉 All tests passed!")
    elif passed > 0:
        print(f"\n⚠️  {total - passed} test(s) failed or skipped")
    else:
        print("\n❌ All tests failed")

if __name__ == "__main__":
    main()
