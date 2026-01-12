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

### 3. Frontend Setup

#### Install Node Dependencies

```bash
cd ../Frontend
npm install
```

#### Configure Environment Variables (Optional)

Create a `.env` file in the Frontend directory if you need to change the API URL:

```
REACT_APP_API_URL=http://localhost:5000/api
```

## Running the Application

### Start the Backend

```bash
cd Backend
python main.py
```

The backend should start on `http://localhost:5000`

### Start the Frontend

In a new terminal:

```bash
cd Frontend
npm start
```

The frontend should start on `http://localhost:3000` and automatically open in your browser.

## Verifying the Setup

1. Check backend health: Visit `http://localhost:5000/api/health`
2. Check frontend: Visit `http://localhost:3000`
3. Check session logs: Look in the `SessionLog/` directory for today's log file

## Troubleshooting

### Backend Issues

- **Port already in use**: Change the `PORT` in `.env` or stop the process using port 5000
- **Module not found**: Make sure you've activated the virtual environment and installed requirements
- **OpenAI API errors**: Verify your API key is correct in `.env`

### Frontend Issues

- **Cannot connect to backend**: Make sure the backend is running on port 5000
- **npm install fails**: Try deleting `node_modules` and `package-lock.json`, then run `npm install` again
- **Port 3000 in use**: React will automatically try the next available port
