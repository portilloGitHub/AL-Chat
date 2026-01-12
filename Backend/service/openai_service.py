"""
OpenAI Service
Business logic for interacting with OpenAI API
Handles sending/receiving prompts and responses
"""
from openai import OpenAI
from typing import Optional, List, Dict
from credentials.credential_manager import CredentialManager


class OpenAIService:
    """Service for interacting with OpenAI API"""
    
    def __init__(self, credential_manager: Optional[CredentialManager] = None):
        """
        Initialize OpenAI service
        
        Args:
            credential_manager: CredentialManager instance. If None, creates a new one.
        """
        if credential_manager is None:
            credential_manager = CredentialManager()
        
        self.credential_manager = credential_manager
        
        # Validate credentials
        is_valid, error_message = credential_manager.validate_openai_credentials()
        if not is_valid:
            raise ValueError(error_message)
        
        # Initialize OpenAI client
        api_key = credential_manager.get_openai_api_key()
        self.client = OpenAI(api_key=api_key)
        self.model = credential_manager.get_openai_model()
    
    def send_message(self, message: str, conversation_history: Optional[List[Dict[str, str]]] = None) -> Dict[str, any]:
        """
        Send a message to OpenAI and get a response with usage statistics
        
        Args:
            message: The user's message/prompt
            conversation_history: List of previous messages in format:
                [{"role": "user", "content": "..."}, {"role": "assistant", "content": "..."}]
        
        Returns:
            Dict with "message" (response text) and "usage" (token usage stats)
        
        Raises:
            Exception: If API call fails
        """
        # Build messages list
        messages = conversation_history.copy() if conversation_history else []
        messages.append({"role": "user", "content": message})
        
        try:
            response = self.client.chat.completions.create(
                model=self.model,
                messages=messages
            )
            
            # Extract usage statistics
            usage = response.usage
            usage_stats = {
                "prompt_tokens": usage.prompt_tokens if usage else 0,
                "completion_tokens": usage.completion_tokens if usage else 0,
                "total_tokens": usage.total_tokens if usage else 0,
                "model": self.model
            }
            
            return {
                "message": response.choices[0].message.content,
                "usage": usage_stats
            }
        
        except Exception as e:
            raise Exception(f"OpenAI API error: {str(e)}")
    
    def chat_completion(self, message: str, conversation_history: Optional[List[Dict[str, str]]] = None) -> Dict[str, any]:
        """
        Alias for send_message for backward compatibility
        """
        return self.send_message(message, conversation_history)
    
    def test_connection(self) -> Dict[str, any]:
        """
        Test the OpenAI connection with a simple prompt
        
        Returns:
            Dict with connection status and test response
        """
        try:
            test_message = "Say 'Connection successful' if you can read this."
            response_data = self.send_message(test_message)
            
            return {
                "status": "success",
                "message": "OpenAI connection is working",
                "test_response": response_data["message"],
                "model": self.model,
                "usage": response_data.get("usage", {})
            }
        except Exception as e:
            return {
                "status": "error",
                "message": f"OpenAI connection failed: {str(e)}",
                "model": self.model
            }
    
    def get_service_info(self) -> Dict[str, any]:
        """Get information about the OpenAI service configuration"""
        return {
            "model": self.model,
            "credentials_valid": True,
            "credentials_info": self.credential_manager.get_credentials_info()
        }
    
    def get_account_info(self) -> Dict[str, any]:
        """
        Get account/organization information from OpenAI API
        
        Returns:
            Dict with account information including organization details
        """
        try:
            # Try to get organization info if available
            # Note: OpenAI API doesn't have a direct account usage endpoint
            # But we can get organization info from the API key
            account_info = {
                "api_key_prefix": self.credential_manager.get_openai_api_key()[:7] + "..." if self.credential_manager.get_openai_api_key() else None,
                "model": self.model,
                "status": "active"
            }
            
            # Try to get organization info (if the API supports it)
            # The OpenAI Python client doesn't have a direct method for this,
            # but we can infer from successful API calls
            return account_info
        except Exception as e:
            return {
                "status": "error",
                "message": f"Could not fetch account info: {str(e)}"
            }
