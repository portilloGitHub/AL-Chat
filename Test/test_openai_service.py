"""
OpenAI Service Test Script
Tests OpenAI service directly (without Flask)
"""
import sys
import io
from pathlib import Path

# Fix Windows console encoding
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

# Add Backend to path
backend_path = Path(__file__).parent.parent / "Backend"
sys.path.insert(0, str(backend_path))

from credentials.credential_manager import CredentialManager
from service.openai_service import OpenAIService

def test_openai_service():
    """Test OpenAI service"""
    print("\n" + "="*60)
    print("  Testing OpenAI Service")
    print("="*60)
    
    try:
        # Initialize credential manager
        print("\n1. Initializing CredentialManager...")
        credential_manager = CredentialManager()
        
        # Validate credentials first
        is_valid, error = credential_manager.validate_openai_credentials()
        if not is_valid:
            print(f"   ❌ Credentials not valid: {error}")
            return False
        
        print("   [OK] Credentials validated")
        
        # Initialize OpenAI service
        print("\n2. Initializing OpenAIService...")
        openai_service = OpenAIService(credential_manager)
        print("   [OK] OpenAIService initialized")
        
        # Get service info
        print("\n3. Getting service info...")
        info = openai_service.get_service_info()
        print(f"   Model: {info['model']}")
        print(f"   Credentials Valid: {info['credentials_valid']}")
        
        # Test connection
        print("\n4. Testing OpenAI connection...")
        test_result = openai_service.test_connection()
        print(f"   Status: {test_result['status']}")
        print(f"   Message: {test_result['message']}")
        
        if test_result['status'] == 'success':
            print(f"   Test Response: {test_result.get('test_response', 'N/A')}")
            print("   [OK] Connection test successful!")
        else:
            print("   [ERROR] Connection test failed")
            return False
        
        # Test sending a message
        print("\n5. Testing send_message()...")
        response = openai_service.send_message("Say 'Hello from test!' if you can read this.")
        print(f"   Response: {response}")
        print("   [OK] Message sent successfully!")
        
        return True
        
    except ValueError as e:
        print(f"   [ERROR] Configuration Error: {str(e)}")
        return False
    except Exception as e:
        print(f"   [ERROR] {str(e)}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = test_openai_service()
    sys.exit(0 if success else 1)
