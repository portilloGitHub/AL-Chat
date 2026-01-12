# AL-Chat

A local GUI application that connects to OpenAI, built with Python backend and React frontend.

## Quick Start

See [Docs/SETUP.md](Docs/SETUP.md) for detailed setup instructions.

### Quick Setup

1. **Backend Setup:**
   ```bash
   cd Backend
   python -m venv venv
   venv\Scripts\activate  # Windows
   pip install -r requirements.txt
   # Create .env file with your OPENAI_API_KEY
   python main.py
   ```

2. **Frontend Setup:**
   ```bash
   cd Frontend
   npm install
   npm start
   ```

## Project Structure

- `Backend/` - Python Flask backend with OpenAI integration
- `Frontend/` - React frontend application
- `Test/` - All test scripts and test-related files
- `CodeReview/` - Code review notes and feedback
- `SessionLog/` - Daily session logs (auto-generated)
- `Docs/` - All documentation files

## Features

- ✅ Modern React UI
- ✅ OpenAI API integration
- ✅ Session logging with daily rotation
- ✅ Metrics tracking
- ✅ Conversation history

## Documentation

- [Setup Guide](Docs/SETUP.md)
- [Architecture Overview](Docs/ARCHITECTURE.md)
- [Contributing Guidelines](Docs/CONTRIBUTING.md)
- [Test Rules](Test/TEST_RULES.md)

## License

MIT License
