# Architecture Overview

## System Architecture

AL-Chat is a backend-only API service that integrates with the main website project.

```
┌─────────────────┐         HTTP/REST API         ┌─────────────┐
│  Main Website   │ ◄───────────────────────────► │   Flask     │
│  (ChatWindow)   │                                │  Backend    │
│  (Port 3001)    │                                │ (Port 5000) │
└─────────────────┘                                └──────┬──────┘
                                                           │
                                                           ▼
                                                   ┌─────────────┐
                                                   │   OpenAI    │
                                                   │     API     │
                                                   └─────────────┘
                                                           │
                                                           ▼
                                                   ┌─────────────┐
                                                   │  Papita API │
                                                   │ (Credentials)│
                                                   │ (Port 3000) │
                                                   └─────────────┘
```

## Component Structure

### Backend (`Backend/`)

- **main.py**: Flask application entry point, API routes
- **session_logger.py**: Session logging module with daily rotation
- **credentials/credential_manager.py**: Credential management (fetches from Papita API)
- **service/openai_service.py**: OpenAI API integration service
- **requirements.txt**: Python dependencies

### Integration

- **Main Website**: Handles all frontend/GUI via `ChatWindow.js` component
- **Papita API**: Provides centralized credential management
- **AL-Chat Backend**: Provides chat API endpoints

### Session Logging (`SessionLog/`)

- Daily log files: `session_YYYY-MM-DD.log`
- JSON format for easy parsing
- Automatic rotation at midnight

## Data Flow

1. User interacts with ChatWindow in main website
2. ChatWindow sends POST request to AL-Chat backend `/api/chat`
3. Backend fetches credentials from Papita API (if available)
4. Backend processes request and calls OpenAI API
5. Backend returns response to ChatWindow
6. ChatWindow displays response in chat interface
7. Session logger tracks all interactions

## Credential Management

- **Local Development**: Uses `.env` file (fallback)
- **Production/Staging**: Fetches from Papita API (`http://localhost:3000/api/credentials/global/openai`)
- **Priority**: Papita API first, then `.env` file

## Session Management

- Session starts when ChatWindow initializes
- Session ID is generated: `session_YYYYMMDD_HHMMSS`
- Session stops when ChatWindow closes or user starts new session
- Metrics are logged with session stop event
- New log file created each day automatically

## Security Considerations

- API keys stored in Papita API (production) or `.env` files (local dev)
- CORS enabled for all origins (backend-only service)
- Input validation on backend
- Error handling with proper HTTP status codes
