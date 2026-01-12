"""
Quick Prompt Test
Test OpenAI service with a specific prompt
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

def test_prompt(prompt):
    """Test a specific prompt"""
    print("\n" + "="*70)
    print("  Testing OpenAI Service with Prompt")
    print("="*70)
    print(f"\nPrompt: {prompt}\n")
    
    try:
        # Initialize services
        credential_manager = CredentialManager()
        openai_service = OpenAIService(credential_manager)
        
        # Send the prompt
        print("Sending prompt to OpenAI...")
        print("-" * 70)
        
        response = openai_service.send_message(prompt)
        
        print("\nResponse:")
        print("=" * 70)
        print(response)
        print("=" * 70)
        
        print("\n[OK] Prompt test successful!")
        return True
        
    except ValueError as e:
        print(f"\n[ERROR] Configuration Error: {str(e)}")
        return False
    except Exception as e:
        print(f"\n[ERROR] {str(e)}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    prompt = "Tell me a dad joke"
    success = test_prompt(prompt)
    sys.exit(0 if success else 1)
