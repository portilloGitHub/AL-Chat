const { app, BrowserWindow } = require('electron');
const path = require('path');
const isDev = require('electron-is-dev');

let mainWindow;

function createWindow() {
  // Create the browser window
  mainWindow = new BrowserWindow({
    width: 1200,
    height: 800,
    minWidth: 800,
    minHeight: 600,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      enableRemoteModule: false,
      preload: path.join(__dirname, 'preload.js'),
      webSecurity: isDev ? false : true  // Disable in dev to avoid CORS issues
    },
    // No custom icon - using default Electron icon
    titleBarStyle: 'default',
    show: true  // Show immediately so we can see what's happening
  });

  // Load the app - always use localhost in dev mode
  const startUrl = 'http://localhost:3000';
  console.log('Loading URL:', startUrl);
  
  // Handle page load errors
  mainWindow.webContents.on('did-fail-load', (event, errorCode, errorDescription, validatedURL) => {
    console.error('Failed to load:', errorCode, errorDescription, validatedURL);
    if (errorCode !== -3) { // -3 is ERR_ABORTED, which we can ignore
      // Wait a bit and retry (React dev server might still be starting)
      console.log('Waiting for React dev server...');
      setTimeout(() => {
        console.log('Retrying to load:', startUrl);
        mainWindow.loadURL(startUrl);
      }, 3000);
    }
  });

  // Handle console messages for debugging
  mainWindow.webContents.on('console-message', (event, level, message) => {
    console.log(`[${level}] ${message}`);
  });

  // DevTools disabled - only open chat window
  // To enable DevTools for debugging, uncomment the line below:
  // if (isDev) { mainWindow.webContents.openDevTools(); }

  mainWindow.loadURL(startUrl);

  // Show window when ready
  mainWindow.once('ready-to-show', () => {
    console.log('Window ready to show');
    mainWindow.focus();
  });

  // Handle window closed
  mainWindow.on('closed', () => {
    console.log('Window closed');
    mainWindow = null;
  });

  // Handle external links
  mainWindow.webContents.setWindowOpenHandler(({ url }) => {
    require('electron').shell.openExternal(url);
    return { action: 'deny' };
  });
}

// This method will be called when Electron has finished initialization
app.whenReady().then(() => {
  console.log('Electron app ready');
  try {
    createWindow();
  } catch (error) {
    console.error('Error creating window:', error);
  }

  app.on('activate', () => {
    // On macOS, re-create window when dock icon is clicked
    if (BrowserWindow.getAllWindows().length === 0) {
      try {
        createWindow();
      } catch (error) {
        console.error('Error creating window on activate:', error);
      }
    }
  });
}).catch((error) => {
  console.error('Error in app.whenReady:', error);
});

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
  console.error(error.stack);
  // Don't exit - keep window open for debugging
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
  // Don't exit - keep window open for debugging
});

// Quit when all windows are closed
app.on('window-all-closed', () => {
  console.log('All windows closed');
  // On macOS, keep app running even when all windows are closed
  // On Windows/Linux, quit immediately
  if (process.platform !== 'darwin') {
    // Give a small delay to ensure window close is processed
    setTimeout(() => {
      app.quit();
    }, 100);
  }
});

// Security: Prevent new window creation
app.on('web-contents-created', (event, contents) => {
  contents.on('new-window', (event, navigationUrl) => {
    event.preventDefault();
    require('electron').shell.openExternal(navigationUrl);
  });
});
