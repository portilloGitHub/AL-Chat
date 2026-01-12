const { app, BrowserWindow, Menu, shell, ipcMain } = require('electron');
const path = require('path');
const isDev = require('electron-is-dev');
const { spawn, exec } = require('child_process');
const os = require('os');

let mainWindow;
let splashWindow = null;
let backendProcess = null;

// Function to find and kill backend process
function killBackendProcess() {
  return new Promise((resolve) => {
    const platform = os.platform();
    let completedTasks = 0;
    const totalTasks = 2; // Kill port 5000 processes + close cmd windows
    
    const checkComplete = () => {
      completedTasks++;
      if (completedTasks >= totalTasks) {
        setTimeout(resolve, 500);
      }
    };
    
    if (platform === 'win32') {
      // Task 1: Find and kill processes on port 5000 (Python backend)
      exec('netstat -ano | findstr :5000', (err, output) => {
        if (!err && output) {
          const lines = output.trim().split('\n');
          const pids = new Set();
          
          lines.forEach(line => {
            const parts = line.trim().split(/\s+/);
            const pid = parts[parts.length - 1];
            if (pid && !isNaN(pid)) {
              pids.add(pid);
            }
          });
          
          if (pids.size > 0) {
            let killCount = 0;
            pids.forEach(pid => {
              console.log(`Killing process on port 5000: PID ${pid}`);
              exec(`taskkill /F /PID ${pid}`, (killError) => {
                killCount++;
                if (killError) {
                  console.log(`Error killing PID ${pid}:`, killError.message);
                } else {
                  console.log(`Successfully killed PID ${pid}`);
                }
                if (killCount === pids.size) {
                  checkComplete();
                }
              });
            });
          } else {
            console.log('No process found on port 5000');
            checkComplete();
          }
        } else {
          console.log('No process found on port 5000');
          checkComplete();
        }
      });
      
      // Task 2: Close cmd windows with "AL-Chat Backend" title
      // Find cmd.exe processes that have "AL-Chat Backend" or "main.py" in their command line
      exec('wmic process where "name=\'cmd.exe\'" get processid,commandline /format:list', (error, stdout) => {
        if (!error && stdout) {
          const backendPids = new Set();
          const lines = stdout.split('\n');
          let currentPid = null;
          
          lines.forEach(line => {
            const trimmed = line.trim();
            if (trimmed.startsWith('ProcessId=')) {
              currentPid = trimmed.split('=')[1];
            } else if (trimmed.startsWith('CommandLine=') && currentPid) {
              const cmdLine = trimmed.split('=').slice(1).join('=');
              if (cmdLine.includes('AL-Chat Backend') || cmdLine.includes('main.py') || cmdLine.includes('Backend\\main.py')) {
                backendPids.add(currentPid);
              }
              currentPid = null;
            }
          });
          
          if (backendPids.size > 0) {
            console.log(`Found ${backendPids.size} backend cmd window(s) to close`);
            let killCount = 0;
            backendPids.forEach(pid => {
              console.log(`Closing backend cmd window: PID ${pid}`);
              exec(`taskkill /F /PID ${pid} /T`, (killError) => {
                killCount++;
                if (killError) {
                  console.log(`Error closing cmd window PID ${pid}:`, killError.message);
                } else {
                  console.log(`Successfully closed cmd window PID ${pid}`);
                }
                if (killCount === backendPids.size) {
                  checkComplete();
                }
              });
            });
          } else {
            console.log('No backend cmd windows found by process search');
            // Fallback: Try PowerShell to find windows by title
            exec('powershell -Command "Get-Process | Where-Object {$_.MainWindowTitle -like \'*AL-Chat Backend*\'} | ForEach-Object { $_.Id }"', (psError, psOutput) => {
              if (!psError && psOutput) {
                const pids = psOutput.trim().split('\n').filter(pid => pid && !isNaN(pid));
                if (pids.length > 0) {
                  let killCount = 0;
                  pids.forEach(pid => {
                    console.log(`Closing backend window via PowerShell: PID ${pid}`);
                    exec(`taskkill /F /PID ${pid} /T`, (killError) => {
                      killCount++;
                      if (killCount === pids.length) {
                        checkComplete();
                      }
                    });
                  });
                } else {
                  checkComplete();
                }
              } else {
                checkComplete();
              }
            });
          }
        } else {
          console.log('Error finding cmd processes, trying PowerShell fallback');
          // Fallback: Use PowerShell to find windows by title
          exec('powershell -Command "Get-Process | Where-Object {$_.MainWindowTitle -like \'*AL-Chat Backend*\'} | ForEach-Object { $_.Id }"', (psError, psOutput) => {
            if (!psError && psOutput) {
              const pids = psOutput.trim().split('\n').filter(pid => pid && !isNaN(pid));
              if (pids.length > 0) {
                let killCount = 0;
                pids.forEach(pid => {
                  console.log(`Closing backend window: PID ${pid}`);
                  exec(`taskkill /F /PID ${pid} /T`, (killError) => {
                    killCount++;
                    if (killCount === pids.length) {
                      checkComplete();
                    }
                  });
                });
              } else {
                checkComplete();
              }
            } else {
              checkComplete();
            }
          });
        }
      });
    } else {
      // macOS/Linux: Find and kill process on port 5000
      exec('lsof -ti:5000', (error, stdout) => {
        if (error) {
          console.log('No process found on port 5000');
          checkComplete();
        } else {
          const pids = stdout.trim().split('\n').filter(pid => pid);
          if (pids.length > 0) {
            let killCount = 0;
            pids.forEach(pid => {
              console.log(`Killing process on port 5000: PID ${pid}`);
              exec(`kill -9 ${pid}`, (killError) => {
                killCount++;
                if (killError) {
                  console.log(`Error killing PID ${pid}:`, killError.message);
                } else {
                  console.log(`Successfully killed PID ${pid}`);
                }
                if (killCount === pids.length) {
                  checkComplete();
                }
              });
            });
          } else {
            checkComplete();
          }
        }
      });
      // macOS/Linux doesn't have separate terminal windows, so only one task
      completedTasks++;
      checkComplete();
    }
  });
}

// Function to start backend process
function startBackendProcess() {
  return new Promise((resolve, reject) => {
    const platform = os.platform();
    const backendDir = path.join(__dirname, '..', '..', 'Backend');
    
    console.log('Starting backend process...');
    console.log('Backend dir:', backendDir);
    
    if (platform === 'win32') {
      // On Windows, start backend in a new window (like the batch file does)
      const startScript = `cd /d "${backendDir}" && title AL-Chat Backend && echo ======================================== && echo   AL-Chat Backend Server && echo ======================================== && echo. && echo Restarting backend on http://localhost:5000 && echo. && py -3.11 main.py || python main.py && echo. && echo Backend stopped. Press any key to close... && pause`;
      
      const backendProcess = spawn('cmd', ['/c', 'start', 'cmd', '/k', startScript], {
        shell: true,
        detached: true,
        stdio: 'ignore'
      });
      
      backendProcess.on('error', (error) => {
        console.error('Failed to start backend:', error);
        reject(error);
      });
      
      // Process is detached, so we don't track it
      setTimeout(() => {
        console.log('Backend window should be opening...');
        resolve(null);
      }, 1000);
    } else {
      // macOS/Linux: Start backend directly
      const pythonCmd = 'python3';
      const backendProcess = spawn(pythonCmd, ['main.py'], {
        cwd: backendDir,
        shell: true,
        detached: true,
        stdio: 'ignore'
      });
      
      backendProcess.on('error', (error) => {
        console.error('Failed to start backend:', error);
        reject(error);
      });
      
      backendProcess.unref(); // Allow Node to exit independently
      setTimeout(() => {
        console.log('Backend process started');
        resolve(backendProcess);
      }, 1000);
    }
  });
}

// Function to restart backend
async function restartBackend() {
  console.log('Restarting backend...');
  
  try {
    // Kill existing backend
    await killBackendProcess();
    
    // Wait a moment for processes to terminate
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    // Start new backend
    backendProcess = await startBackendProcess();
    console.log('Backend restarted successfully');
    
    // Show notification to user
    if (mainWindow) {
      mainWindow.webContents.send('backend-restarted');
    }
  } catch (error) {
    console.error('Error restarting backend:', error);
    if (mainWindow) {
      mainWindow.webContents.send('backend-restart-error', error.message);
    }
  }
}

// Create splash screen
function createSplashWindow() {
  splashWindow = new BrowserWindow({
    width: 400,
    height: 500,
    frame: false,
    transparent: true,
    alwaysOnTop: true,
    resizable: false,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true
    },
    show: false
  });

  splashWindow.loadFile(path.join(__dirname, 'splash.html'));
  
  splashWindow.once('ready-to-show', () => {
    if (splashWindow) {
      splashWindow.show();
      // Center the splash window
      splashWindow.center();
    }
  });

  return splashWindow;
}

// Close splash screen
function closeSplashWindow() {
  if (splashWindow) {
    splashWindow.close();
    splashWindow = null;
  }
}

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
    show: false  // Don't show until ready
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

  // Show window when ready and close splash
  mainWindow.once('ready-to-show', () => {
    console.log('Window ready to show');
    // Close splash screen
    closeSplashWindow();
    // Show main window
    mainWindow.show();
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

// Create application menu
function createMenu() {
  const template = [
    {
      label: 'File',
      submenu: [
        {
          label: 'Exit',
          accelerator: process.platform === 'darwin' ? 'Cmd+Q' : 'Ctrl+Q',
          click: async () => {
            await cleanupBackend();
            app.quit();
          }
        }
      ]
    },
    {
      label: 'Debug',
      submenu: [
        {
          label: 'Restart Backend',
          accelerator: 'CmdOrCtrl+Shift+R',
          click: () => {
            restartBackend();
          }
        },
        { type: 'separator' },
        {
          label: 'Toggle Developer Tools',
          accelerator: process.platform === 'darwin' ? 'Alt+Cmd+I' : 'Ctrl+Shift+I',
          click: (item, focusedWindow) => {
            if (focusedWindow) {
              focusedWindow.webContents.toggleDevTools();
            }
          }
        }
      ]
    }
  ];

  // macOS specific menu adjustments
  if (process.platform === 'darwin') {
    template.unshift({
      label: app.getName(),
      submenu: [
        { role: 'about' },
        { type: 'separator' },
        { role: 'services' },
        { type: 'separator' },
        { role: 'hide' },
        { role: 'hideOthers' },
        { role: 'unhide' },
        { type: 'separator' },
        { role: 'quit' }
      ]
    });
  }

  const menu = Menu.buildFromTemplate(template);
  Menu.setApplicationMenu(menu);
}

// This method will be called when Electron has finished initialization
app.whenReady().then(() => {
  console.log('Electron app ready');
  
  // Create application menu
  createMenu();
  
  // Create splash screen first
  createSplashWindow();
  
  // Small delay to show splash, then create main window
  setTimeout(() => {
    try {
      createWindow();
    } catch (error) {
      console.error('Error creating window:', error);
      closeSplashWindow();
    }
  }, 500);

  app.on('activate', () => {
    // On macOS, re-create window when dock icon is clicked
    if (BrowserWindow.getAllWindows().length === 0) {
      try {
        createSplashWindow();
        setTimeout(() => {
          createWindow();
        }, 500);
      } catch (error) {
        console.error('Error creating window on activate:', error);
        closeSplashWindow();
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

// Cleanup function to kill backend when app quits
async function cleanupBackend() {
  console.log('Cleaning up backend processes...');
  try {
    await killBackendProcess();
  } catch (error) {
    console.error('Error cleaning up backend:', error);
  }
}

// Cleanup function for splash screen
function cleanupSplash() {
  closeSplashWindow();
}

// Handle app before-quit to cleanup backend
app.on('before-quit', async (event) => {
  console.log('App quitting - cleaning up backend...');
  cleanupSplash();
  await cleanupBackend();
  // Give a moment for cleanup
  await new Promise(resolve => setTimeout(resolve, 500));
});

// Quit when all windows are closed
app.on('window-all-closed', async () => {
  console.log('All windows closed');
  // Cleanup backend before quitting
  await cleanupBackend();
  
  // On macOS, keep app running even when all windows are closed
  // On Windows/Linux, quit immediately
  if (process.platform !== 'darwin') {
    // Give a small delay to ensure cleanup and window close are processed
    setTimeout(() => {
      app.quit();
    }, 1000);
  }
});

// IPC handlers for backend restart
ipcMain.on('restart-backend', async () => {
  await restartBackend();
});

// Security: Prevent new window creation
app.on('web-contents-created', (event, contents) => {
  contents.on('new-window', (event, navigationUrl) => {
    event.preventDefault();
    require('electron').shell.openExternal(navigationUrl);
  });
});
