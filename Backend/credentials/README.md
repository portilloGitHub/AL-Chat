# Credentials Module

Handles loading and managing API credentials securely.

## Structure

- `credential_manager.py` - Main credential management class

## Usage

```python
from credentials.credential_manager import CredentialManager

# Initialize credential manager
credential_manager = CredentialManager()

# Get OpenAI API key
api_key = credential_manager.get_openai_api_key()

# Validate credentials
is_valid, error = credential_manager.validate_openai_credentials()
```

## Environment Variables

Credentials are loaded from `.env` file in the Backend directory:

```
OPENAI_API_KEY=your_api_key_here
OPENAI_MODEL=gpt-3.5-turbo
```

## Security

- Never commit `.env` files to git
- API keys are stored in environment variables, not in code
- Credential manager validates key format before use
