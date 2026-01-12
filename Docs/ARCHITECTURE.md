# Architecture Overview

## System Architecture

AL-Chat follows a client-server architecture with a clear separation between frontend and backend.

```
┌─────────────┐         HTTP/REST API         ┌─────────────┐
│   React     │ ◄───────────────────────────► │   Flask     │
│  Frontend   │                                │  Backend    │
│  (Port 3000)│                                │ (Port 5000) │
└─────────────┘                                └──────┬──────┘
                                                      │
                                                      ▼
                                              ┌─────────────┐
                                              │   OpenAI    │
                                              │     API     │
                                              └─────────────┘
```

## Component Structure

### Backend (`Backend/`)

- **main.py**: Flask application entry point, API routes
- **session_logger.py**: Session logging module with daily rotation
- **requirements.txt**: Python dependencies

### Frontend (`Frontend/`)

- **src/App.js**: Main React component
- **src/components/ChatInterface.js**: Chat UI component
- **src/services/apiService.js**: API communication layer
- **src/services/sessionService.js**: Session management service

### Session Logging (`SessionLog/`)

- Daily log files: `session_YYYY-MM-DD.log`
- JSON format for easy parsing
- Automatic rotation at midnight

## Data Flow

1. User types message in React frontend
2. Frontend sends POST request to `/api/chat`
3. Backend processes request and calls OpenAI API
4. Backend returns response to frontend
5. Frontend displays response in chat interface
6. Session logger tracks all interactions

## Session Management

- Session starts when the app loads
- Session ID is generated: `session_YYYYMMDD_HHMMSS`
- Session stops when the app closes
- Metrics are logged with session stop event
- New log file created each day automatically

## Security Considerations

- API keys stored in `.env` files (not committed to git)
- CORS enabled for local development
- Input validation on backend
- Error handling on both frontend and backend
