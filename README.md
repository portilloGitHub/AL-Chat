# AL-Chat Backend API

Backend API service for AL-Chat, integrated with the main website project. All GUI/frontend work is handled by the main website.

## Overview

AL-Chat is a backend-only API service that provides:
- OpenAI integration for chat functionality
- Session management and logging
- Credential management (fetches from Papita API)
- RESTful API endpoints for chat operations

## Quick Start

See [Docs/SETUP.md](Docs/SETUP.md) for detailed setup instructions.

### Backend Setup

```bash
cd Backend
python -m venv venv
venv\Scripts\activate  # Windows
pip install -r requirements.txt
# Create .env file (see Backend/env_template.txt)
python main.py
```

The backend will run on `http://localhost:5000`

## Project Structure

- `Backend/` - Python Flask backend API
- `Test/` - Test scripts and test-related files
- `CodeReview/` - Code review notes and feedback
- `SessionLog/` - Daily session logs (auto-generated)
- `Docs/` - Documentation files
- `scripts/` - Deployment scripts
- `deploy/` - Deployment configurations

## Features

- ✅ RESTful API endpoints
- ✅ OpenAI API integration
- ✅ Session logging with daily rotation
- ✅ Metrics tracking
- ✅ Credential management (Papita API integration)
- ✅ Docker containerization
- ✅ Health check endpoints

## API Endpoints

- `GET /api/health` - Health check
- `POST /api/chat` - Send chat message
- `POST /api/session/start` - Start new session
- `POST /api/session/stop` - Stop session
- `GET /api/openai/info` - Get OpenAI service info
- `GET /api/openai/usage` - Get usage statistics

## Integration

This backend is designed to be integrated with the main website project:
- Frontend GUI is handled by main website's `ChatWindow.js`
- Credentials are fetched from Papita API (`http://localhost:3000/api/credentials/global/openai`)
- Backend runs as a Docker container or standalone service

## Documentation

- [Setup Guide](Docs/SETUP.md)
- [Architecture Overview](Docs/ARCHITECTURE.md)
- [Integration Guide](Docs/INTEGRATION_REVIEW.md)
- [Local Integration Testing](Docs/LOCAL_INTEGRATION_TEST.md)
- [Deployment Guide](Docs/DEPLOYMENT.md)
- [Staging Deployment](Docs/STAGING_DEPLOYMENT.md)

## License

MIT License
