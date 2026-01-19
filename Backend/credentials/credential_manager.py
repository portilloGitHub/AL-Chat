"""
Credential Manager
Handles loading and validation of API credentials from Papita API or environment variables
"""
import os
from pathlib import Path
from dotenv import load_dotenv
from typing import Optional
import httpx


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
        self.papita_api_url = os.getenv('PAPITA_API_URL', 'http://localhost:3000')
        self._credential_source = None  # Track which source was used
        self._load_credentials()
    
    def _load_credentials(self):
        """Load credentials from .env file (fallback for local development)"""
        if self.env_file.exists():
            load_dotenv(dotenv_path=self.env_file)
        else:
            # Try to load from current directory as fallback
            load_dotenv()
    
    def _fetch_from_papita_api(self) -> Optional[str]:
        """
        Fetch OpenAI API key from Papita API
        
        Returns:
            API key string if successful, None otherwise
        """
        try:
            url = f"{self.papita_api_url}/api/credentials/global/openai"
            # Use a shorter timeout and catch all connection errors
            with httpx.Client(timeout=2.0) as client:
                response = client.get(url)
                
                if response.status_code == 200:
                    data = response.json()
                    # Handle different response formats
                    if isinstance(data, dict):
                        # Try common response formats
                        # Papita API format: data.credentials.credentials.api_key
                        api_key = (
                            data.get('credentials', {}).get('credentials', {}).get('api_key') or
                            data.get('credentials', {}).get('api_key') or
                            data.get('api_key') or
                            data.get('value') or
                            data.get('credential_value')
                        )
                        if api_key and api_key.strip():
                            return api_key.strip()
            
            return None
        except Exception as e:
            # Silently fail - will fallback to .env
            # Only print if in debug mode to avoid cluttering output
            if os.getenv('FLASK_ENV') == 'development':
                error_msg = str(e)
                # Only show connection errors, not all exceptions
                if 'connect' in error_msg.lower() or 'refused' in error_msg.lower():
                    pass  # Suppress connection errors in dev mode too
            return None
    
    def get_openai_api_key(self) -> Optional[str]:
        """
        Get OpenAI API key from Papita API or environment
        
        Priority:
        1. Try Papita API (for production/integration)
        2. Fallback to local .env file (for local development)
        """
        # First, try fetching from Papita API
        api_key = self._fetch_from_papita_api()
        
        if api_key and api_key.strip():
            self._credential_source = "papita_api"
            return api_key.strip()
        
        # Fallback to local .env file
        api_key = os.getenv('OPENAI_API_KEY')
        if api_key and api_key.strip():
            self._credential_source = "local_env"
            return api_key.strip()
        
        self._credential_source = None
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
            "env_file_exists": self.env_file.exists(),
            "papita_api_url": self.papita_api_url,
            "credential_source": self._credential_source or "none"
        }
