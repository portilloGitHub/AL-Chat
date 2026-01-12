# AL-Chat

A local GUI application that connects to OpenAI, built with Python backend and React frontend.

## Project Structure

```
AL-Chat/
├── Backend/          # Python Flask backend
├── Frontend/         # React frontend application
├── Test/             # All test scripts and test-related files
├── CodeReview/       # Code review notes and feedback
├── SessionLog/       # Daily session logs
└── Docs/            # Documentation files
```

## Features

- **Local GUI**: Beautiful, modern React-based user interface
- **OpenAI Integration**: Connect to your OpenAI account
- **Session Logging**: Automatic session tracking with daily log rotation
- **Metrics Tracking**: Track session metrics and statistics

## Getting Started

### Prerequisites

- Python 3.8+
- Node.js 16+
- npm or yarn
- OpenAI API key

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

5. Create a `.env` file from `.env.example`:
   ```bash
   copy .env.example .env
   ```

6. Add your OpenAI API key to `.env`:
   ```
   OPENAI_API_KEY=your_api_key_here
   ```

7. Run the backend server:
   ```bash
   python main.py
   ```

The backend will run on `http://localhost:5000`

### Frontend Setup

1. Navigate to the Frontend directory:
   ```bash
   cd Frontend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Start the development server:
   ```bash
   npm start
   ```

The frontend will run on `http://localhost:3000`

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
  - Body: `{ "message": "your message here" }`

### Session Management
- `POST /api/session/start` - Start a new session
- `POST /api/session/stop` - Stop the current session
  - Body: `{ "session_id": "...", "metrics": { ... } }`

## Development

### Backend Development
The backend uses Flask with CORS enabled for development. Make sure to set `FLASK_ENV=development` in your `.env` file.

### Frontend Development
The frontend uses Create React App. The development server includes hot-reloading.

### Testing
All test-related files go in the `Test/` folder. See [Test/README.md](../Test/README.md) and [PROJECT_RULES.md](PROJECT_RULES.md) for details.

## License

MIT License
