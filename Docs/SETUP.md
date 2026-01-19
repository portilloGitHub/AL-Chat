# Setup Guide

This guide will help you set up the AL-Chat project from scratch.

## Initial Setup

### 1. Clone the Repository

```bash
git clone https://github.com/portilloGitHub/AL-Chat.git
cd AL-Chat
```

### 2. Backend Setup

#### Install Python Dependencies

```bash
cd Backend
python -m venv venv

# Windows
venv\Scripts\activate

# macOS/Linux
source venv/bin/activate

pip install -r requirements.txt
```

#### Configure Environment Variables

1. Copy the example environment file:
   ```bash
   copy .env.example .env  # Windows
   cp .env.example .env    # macOS/Linux
   ```

2. Edit `.env` and add your OpenAI API key:
   ```
   OPENAI_API_KEY=sk-your-actual-api-key-here
   PORT=5000
   FLASK_ENV=development
   ```

## Running the Application

### Start the Backend

```bash
cd Backend
python main.py
```

The backend should start on `http://localhost:5000`

**Note:** Frontend/GUI is handled by the main website project. This is a backend-only API service.

## Verifying the Setup

1. Check backend health: Visit `http://localhost:5000/api/health` or run:
   ```bash
   curl http://localhost:5000/api/health
   ```
2. Check session logs: Look in the `SessionLog/` directory for today's log file
3. Test integration: Use the main website's ChatWindow component to connect to this backend

## Troubleshooting

### Backend Issues

- **Port already in use**: Change the `PORT` in `.env` or stop the process using port 5000
- **Module not found**: Make sure you've activated the virtual environment and installed requirements
- **OpenAI API errors**: Verify your API key is correct in `.env`

### Integration Issues

- **Cannot connect from main website**: Make sure the backend is running on port 5000
- **CORS errors**: Backend has CORS enabled for all origins. If issues persist, check backend logs
- **Credentials not found**: Ensure Papita API is running on port 3000, or set `OPENAI_API_KEY` in `.env` file
