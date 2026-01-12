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
    
    def send_message(self, message: str, conversation_history: Optional[List[Dict[str, str]]] = None) -> str:
        """
        Send a message to OpenAI and get a response
        
        Args:
            message: The user's message/prompt
            conversation_history: List of previous messages in format:
                [{"role": "user", "content": "..."}, {"role": "assistant", "content": "..."}]
        
        Returns:
            The assistant's response message
        
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
            
            return response.choices[0].message.content
        
        except Exception as e:
            raise Exception(f"OpenAI API error: {str(e)}")
    
    def chat_completion(self, message: str, conversation_history: Optional[List[Dict[str, str]]] = None) -> str:
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
            response = self.send_message(test_message)
            
            return {
                "status": "success",
                "message": "OpenAI connection is working",
                "test_response": response,
                "model": self.model
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
