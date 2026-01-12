# AL-Chat Backend

Python Flask backend for AL-Chat application.

## Setup

1. Create virtual environment:
   ```bash
   python -m venv venv
   venv\Scripts\activate  # Windows
   source venv/bin/activate  # macOS/Linux
   ```

2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Configure environment:
   - Copy `env_template.txt` to `.env`
   - Add your OpenAI API key

4. Run the server:
   ```bash
   python main.py
   ```

The server will run on `http://localhost:5000` by default.

## API Endpoints

- `GET /api/health` - Health check
- `POST /api/chat` - Send chat message
- `POST /api/session/start` - Start session
- `POST /api/session/stop` - Stop session
