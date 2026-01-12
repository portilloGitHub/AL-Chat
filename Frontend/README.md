# AL-Chat Frontend

React + Electron desktop application for AL-Chat.

## Quick Start

**For normal use (no terminal window):** Double-click `start-al-chat.vbs`

**For debugging (shows terminal):** Double-click `start-al-chat.bat`

The launcher will handle everything:
- Check for Node.js
- Install dependencies
- Start React dev server
- Launch Electron window
- Close automatically when you close the app

## Requirements

- Node.js (https://nodejs.org/)
- Python backend running (optional but recommended)

## Project Structure

```
Frontend/
  ├── start-al-chat.vbs     ← Main launcher - NO TERMINAL WINDOW (recommended)
  ├── start-al-chat.bat     ← Debug launcher - shows terminal window
  ├── src/                  ← React source code
  ├── electron/             ← Electron main process
  ├── public/               ← Static files
  └── package.json          ← Dependencies and scripts
```

## Development

### Start the App

```bash
# Option 1: Use the VBScript launcher (recommended - no terminal window)
# Just double-click: start-al-chat.vbs

# Option 2: Use the batch file (shows terminal for debugging)
start-al-chat.bat

# Option 3: Manual start
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
- No executable build needed - just use the VBScript launcher
- The VBScript launcher runs without showing a terminal window (like a normal Windows app)
- Use the batch file launcher if you need to see debug output
