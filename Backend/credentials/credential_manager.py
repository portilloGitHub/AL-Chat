"""
Credential Manager
Handles loading and validation of API credentials from environment variables
"""
import os
from pathlib import Path
from dotenv import load_dotenv
from typing import Optional


class CredentialManager:
    """Manages API credentials for OpenAI and other services"""
    
    def __init__(self, env_file: Optional[str] = None):
        """
        Initialize credential manager
        
        Args:
            env_file: Path to .env file. If None, looks for .env in Backend directory
        """
        if env_file is None:
            # Default to Backend/.env
            backend_dir = Path(__file__).parent.parent
            env_file = backend_dir / '.env'
        
        self.env_file = Path(env_file)
        self._load_credentials()
    
    def _load_credentials(self):
        """Load credentials from .env file"""
        if self.env_file.exists():
            load_dotenv(dotenv_path=self.env_file)
        else:
            # Try to load from current directory as fallback
            load_dotenv()
    
    def get_openai_api_key(self) -> Optional[str]:
        """Get OpenAI API key from environment"""
        api_key = os.getenv('OPENAI_API_KEY')
        if api_key and api_key.strip():
            return api_key.strip()
        return None
    
    def get_openai_model(self) -> str:
        """Get OpenAI model name (default: gpt-3.5-turbo)"""
        return os.getenv('OPENAI_MODEL', 'gpt-3.5-turbo')
    
    def validate_openai_credentials(self):
        """
        Validate OpenAI credentials are present
        
        Returns:
            Tuple of (is_valid, error_message)
        """
        api_key = self.get_openai_api_key()
        if not api_key:
            return False, "OPENAI_API_KEY not found in environment variables. Please set it in .env file."
        
        if api_key.startswith('your_') or api_key.startswith('sk-') is False:
            if not api_key.startswith('sk-'):
                return False, "OPENAI_API_KEY appears to be invalid. OpenAI API keys start with 'sk-'."
        
        return True, None
    
    def get_credentials_info(self) -> dict:
        """Get information about loaded credentials (without exposing keys)"""
        api_key = self.get_openai_api_key()
        return {
            "openai_api_key_set": api_key is not None,
            "openai_api_key_length": len(api_key) if api_key else 0,
            "openai_api_key_prefix": api_key[:7] + "..." if api_key and len(api_key) > 7 else None,
            "openai_model": self.get_openai_model(),
            "env_file_path": str(self.env_file),
            "env_file_exists": self.env_file.exists()
        }
