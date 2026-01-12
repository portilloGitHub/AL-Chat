# AL-Chat Frontend

React + Electron desktop application for AL-Chat.

## Quick Start

**Just double-click:** `start-al-chat.bat`

That's it! The batch file will handle everything:
- Check for Node.js
- Install dependencies
- Start React dev server
- Launch Electron window

## Requirements

- Node.js (https://nodejs.org/)
- Python backend running (optional but recommended)

## Project Structure

```
Frontend/
  ├── start-al-chat.bat    ← Main launcher (double-click this!)
  ├── src/                  ← React source code
  ├── electron/             ← Electron main process
  ├── public/               ← Static files
  └── package.json          ← Dependencies and scripts
```

## Development

### Start the App

```bash
# Option 1: Use the batch file (recommended)
start-al-chat.bat

# Option 2: Manual start
npm run electron-dev
```

### Available Scripts

- `npm start` - Start React dev server
- `npm run electron-dev` - Start Electron with React dev server
- `npm run build` - Build React app for production

## Backend Connection

The frontend connects to the Python backend at `http://localhost:5000`.

Make sure to start the backend:
```bash
cd Backend
python main.py
```

## Notes

- Uses Electron in development mode (connects to localhost:3000)
- Hot-reload enabled for React development
- No executable build needed - just use the batch file launcher
