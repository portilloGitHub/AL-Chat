"""
Credential Test Script
Tests credential loading and validation
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

def test_credential_manager():
    """Test credential manager"""
    print("\n" + "="*60)
    print("  Testing Credential Manager")
    print("="*60)
    
    try:
        # Initialize credential manager
        print("\n1. Initializing CredentialManager...")
        credential_manager = CredentialManager()
        print("   [OK] CredentialManager initialized")
        
        # Get credentials info
        print("\n2. Getting credentials info...")
        info = credential_manager.get_credentials_info()
        print(f"   OpenAI API Key Set: {info['openai_api_key_set']}")
        print(f"   API Key Length: {info['openai_api_key_length']}")
        print(f"   API Key Prefix: {info['openai_api_key_prefix']}")
        print(f"   Model: {info['openai_model']}")
        print(f"   .env File Path: {info['env_file_path']}")
        print(f"   .env File Exists: {info['env_file_exists']}")
        
        # Validate credentials
        print("\n3. Validating credentials...")
        is_valid, error = credential_manager.validate_openai_credentials()
        
        if is_valid:
            print("   [OK] Credentials are valid")
            return True
        else:
            print(f"   [ERROR] Credentials validation failed: {error}")
            print("\n   To fix:")
            print("   1. Create Backend/.env file")
            print("   2. Add: OPENAI_API_KEY=sk-your-key-here")
            return False
            
    except Exception as e:
        print(f"   [ERROR] {str(e)}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = test_credential_manager()
    sys.exit(0 if success else 1)
