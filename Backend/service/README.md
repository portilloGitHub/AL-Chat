# Service Module

Business logic for interacting with external services.

## Structure

- `openai_service.py` - OpenAI API integration service

## OpenAI Service

Handles all communication with OpenAI API:

### Methods

- `send_message(message, conversation_history)` - Send a message and get AI response
- `test_connection()` - Test OpenAI connection
- `get_service_info()` - Get service configuration info

### Usage

```python
from service.openai_service import OpenAIService
from credentials.credential_manager import CredentialManager

# Initialize
credential_manager = CredentialManager()
openai_service = OpenAIService(credential_manager)

# Send a message
response = openai_service.send_message("Hello, how are you?")

# Test connection
test_result = openai_service.test_connection()
```

## Error Handling

The service validates credentials on initialization and provides clear error messages if:
- API key is missing
- API key format is invalid
- API call fails
