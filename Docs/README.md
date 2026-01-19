# AL-Chat Backend API

Backend API service for AL-Chat, integrated with the main website project. All GUI/frontend work is handled by the main website.

## Project Structure

```
AL-Chat/
├── Backend/          # Python Flask backend API
├── Test/             # All test scripts and test-related files
├── CodeReview/       # Code review notes and feedback
├── SessionLog/       # Daily session logs (auto-generated)
└── Docs/            # Documentation files
```

## Features

- **RESTful API**: Backend-only API service
- **OpenAI Integration**: Connect to OpenAI API
- **Session Logging**: Automatic session tracking with daily log rotation
- **Metrics Tracking**: Track session metrics and statistics
- **Credential Management**: Fetches credentials from Papita API

## Getting Started

### Prerequisites

- Python 3.8+
- OpenAI API key (or Papita API running for credentials)

### Backend Setup

1. Navigate to the Backend directory:
   ```bash
   cd Backend
   ```

2. Create a virtual environment:
   ```bash
   python -m venv venv
   ```

3. Activate the virtual environment:
   - Windows: `venv\Scripts\activate`
   - macOS/Linux: `source venv/bin/activate`

4. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

5. Create a `.env` file from `env_template.txt`:
   ```bash
   copy env_template.txt .env
   ```

6. Add your OpenAI API key to `.env` (for local testing):
   ```
   OPENAI_API_KEY=your_api_key_here
   PAPITA_API_URL=http://localhost:3000
   ```

7. Run the backend server:
   ```bash
   python main.py
   ```

The backend will run on `http://localhost:5000`

**Note:** Frontend/GUI is handled by the main website project. This is a backend-only API service.

## Session Logging

Session logs are automatically created in the `SessionLog/` directory. Each day gets its own log file named `session_YYYY-MM-DD.log`.

### Session Log Format

Each session log entry is a JSON object with the following structure:

```json
{
  "event": "session_start" | "session_stop" | "metric",
  "session_id": "session_YYYYMMDD_HHMMSS",
  "timestamp": "ISO 8601 timestamp",
  "date": "YYYY-MM-DD",
  "duration_seconds": <number>,  // Only for session_stop
  "metrics": { ... }              // Only for session_stop
}
```

## API Endpoints

### Health Check
- `GET /api/health` - Check if the backend is running

### Chat
- `POST /api/chat` - Send a message to OpenAI
  - Body: `{ "message": "your message here", "history": [], "attached_files": [] }`

### Session Management
- `POST /api/session/start` - Start a new session
- `POST /api/session/stop` - Stop the current session
  - Body: `{ "session_id": "...", "metrics": { ... } }`

### OpenAI Info
- `GET /api/openai/info` - Get OpenAI service configuration
- `GET /api/openai/usage` - Get usage statistics

## Integration

This backend is designed to be integrated with the main website project:
- Frontend GUI is handled by main website's `ChatWindow.js`
- Credentials are fetched from Papita API when available
- Backend runs as a Docker container or standalone service

## Development

### Backend Development
The backend uses Flask with CORS enabled for development. Make sure to set `FLASK_ENV=development` in your `.env` file.

### Testing
All test-related files go in the `Test/` folder. See [Test/README.md](../Test/README.md) and [PROJECT_RULES.md](PROJECT_RULES.md) for details.

## License

MIT License
