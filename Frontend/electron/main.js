const { app, BrowserWindow, Menu, shell, ipcMain, dialog } = require('electron');
const path = require('path');
const fs = require('fs');
let mammoth;
try { mammoth = require('mammoth'); } catch (e) { mammoth = null; }
const isDev = require('electron-is-dev');
const { spawn, exec } = require('child_process');
const os = require('os');
const { pathToFileURL } = require('url');

let mainWindow;
let splashWindow = null;
let backendProcess = null;
let selectedMode = null;
let modeSelectionPromise = null;
let modeSelectionResolve = null;

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

// Function to check and install Python dependencies
function checkPythonDependencies(backendDir, pythonCmd) {
  return new Promise((resolve, reject) => {
    exec(`${pythonCmd} -c "import flask"`, { cwd: backendDir }, (error) => {
      if (error) {
        console.log('Python dependencies not found - installing...');
        exec(`${pythonCmd} -m pip install --upgrade -r requirements.txt`, { cwd: backendDir }, (installError) => {
          if (installError) {
            console.error('Failed to install Python dependencies:', installError);
            reject(installError);
          } else {
            console.log('Python dependencies installed');
            resolve();
          }
        });
      } else {
        // Ensure OpenAI is up to date
        exec(`${pythonCmd} -m pip install --upgrade "openai>=1.40.0"`, { cwd: backendDir }, () => {
          console.log('Python dependencies ready');
          resolve();
        });
      }
    });
  });
}

// Function to start backend process
function startBackendProcess() {
  return new Promise((resolve, reject) => {
    const platform = os.platform();
    const backendDir = path.join(__dirname, '..', '..', 'Backend');
    const backendMainPy = path.join(backendDir, 'main.py');
    
    console.log('Starting backend process...');
    console.log('Backend dir:', backendDir);
    
    // Check if backend directory exists
    if (!fs.existsSync(backendMainPy)) {
      reject(new Error(`Backend main.py not found at ${backendMainPy}`));
      return;
    }
    
    // Determine Python command and start backend
    const determinePythonAndStart = async () => {
      let pythonCmd = 'python';
      
      if (platform === 'win32') {
        // Try Python 3.11 first
        exec('py -3.11 --version', async (error) => {
          if (!error) {
            pythonCmd = 'py -3.11';
            await executeBackendStart(pythonCmd);
          } else {
            // Fallback to default python
            exec('python --version', async (pyError) => {
              if (pyError) {
                reject(new Error('Python is not installed or not in PATH'));
              } else {
                await executeBackendStart(pythonCmd);
              }
            });
          }
        });
      } else {
        pythonCmd = 'python3';
        executeBackendStart(pythonCmd);
      }
    };
    
    const executeBackendStart = async (pythonCmd) => {
      try {
        // Check and install dependencies
        await checkPythonDependencies(backendDir, pythonCmd);
        
        if (platform === 'win32') {
          // On Windows, start backend in a new window
          const startScript = `cd /d "${backendDir}" && title AL-Chat Backend && echo ======================================== && echo   AL-Chat Backend Server && echo ======================================== && echo. && echo Using: ${pythonCmd} && echo Starting backend on http://localhost:5000 && echo. && ${pythonCmd} main.py && echo. && echo Backend stopped. Press any key to close... && pause`;
          
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
      } catch (error) {
        reject(error);
      }
    };
    
    determinePythonAndStart();
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
    width: 500,
    height: 600,
    frame: false,
    transparent: true,
    alwaysOnTop: true,
    resizable: false,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'preload.js')
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

// Wait for mode selection from splash screen
function waitForModeSelection() {
  if (modeSelectionPromise) {
    return modeSelectionPromise;
  }
  
  modeSelectionPromise = new Promise((resolve) => {
    modeSelectionResolve = resolve;
  });
  
  return modeSelectionPromise;
}

// Update splash screen status
function updateSplashStatus(message) {
  if (splashWindow && !splashWindow.isDestroyed()) {
    splashWindow.webContents.send('status-update', message);
  }
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

  // Determine which URL to load based on mode
  let startUrl;
  const buildPath = path.join(__dirname, '..', 'build', 'index.html');
  const buildExists = fs.existsSync(buildPath);
  
  // Check environment variable to determine mode
  // ELECTRON_USE_LOCALHOST=true means use localhost (dev mode)
  // ELECTRON_USE_LOCALHOST=false or undefined means use built app (production mode)
  const useLocalhost = process.env.ELECTRON_USE_LOCALHOST === 'true';
  
  if (useLocalhost) {
    // Development mode: use localhost
    startUrl = 'http://localhost:3000';
    console.log('Loading URL (Development/Localhost mode):', startUrl);
  } else if (buildExists) {
    // Production mode: use built app
    // Convert path to file:// URL format
    const fileUrl = pathToFileURL(buildPath).href;
    startUrl = fileUrl;
    console.log('Loading URL (Production/Application mode):', startUrl);
  } else {
    // Fallback: try localhost if build doesn't exist
    startUrl = 'http://localhost:3000';
    console.log('Build not found, falling back to localhost:', startUrl);
  }
  
  // Handle page load errors
  mainWindow.webContents.on('did-fail-load', (event, errorCode, errorDescription, validatedURL) => {
    console.error('Failed to load:', errorCode, errorDescription, validatedURL);
    
    // If loading from file:// failed and we have a build, try localhost as fallback
    if (validatedURL.startsWith('file://') && errorCode !== -3) {
      console.log('Build load failed, trying localhost as fallback...');
      setTimeout(() => {
        const localhostUrl = 'http://localhost:3000';
        console.log('Retrying with localhost:', localhostUrl);
        mainWindow.loadURL(localhostUrl);
      }, 2000);
    } else if (validatedURL.startsWith('http://localhost:3000') && errorCode !== -3) {
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
// Function to show About dialog
function showAboutDialog() {
  const packagePath = path.join(__dirname, '..', 'package.json');
  let version = 'Unknown';
  
  try {
    const packageJson = JSON.parse(fs.readFileSync(packagePath, 'utf8'));
    version = packageJson.version || 'Unknown';
  } catch (error) {
    console.error('Error reading package.json:', error);
  }
  
  dialog.showMessageBox(mainWindow || null, {
    type: 'info',
    title: 'About AL-Chat',
    message: 'AL-Chat',
    detail: `Version ${version}\n\nA desktop chat application powered by OpenAI.`,
    buttons: ['OK'],
    defaultId: 0
  });
}

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
    },
    {
      label: 'Help',
      submenu: [
        {
          label: 'About',
          click: () => {
            showAboutDialog();
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
        {
          label: 'About',
          click: () => {
            showAboutDialog();
          }
        },
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

// Function to wait for backend to be ready
function waitForBackend(maxWaitSeconds = 30) {
  return new Promise((resolve, reject) => {
    const startTime = Date.now();
    let attemptCount = 0;
    
    const checkBackend = () => {
      attemptCount++;
      const platform = os.platform();
      const curlCmd = platform === 'win32' ? 'curl -s http://localhost:5000/api/health' : 'curl -s http://localhost:5000/api/health';
      
      exec(curlCmd, (error, stdout) => {
        if (!error && stdout && stdout.trim()) {
          try {
            const health = JSON.parse(stdout);
            if (health.status === 'healthy') {
              console.log('Backend is ready!');
              resolve(true);
              return;
            }
          } catch (e) {
            // Not JSON yet, keep waiting
          }
        }
        
        const elapsed = (Date.now() - startTime) / 1000;
        if (elapsed >= maxWaitSeconds) {
          console.log(`Backend wait timeout after ${attemptCount} attempts`);
          // Don't reject - just resolve with false so we can continue
          resolve(false);
          return;
        }
        
        // Check again in 1 second
        setTimeout(checkBackend, 1000);
      });
    };
    
    checkBackend();
  });
}

// IPC handler for mode selection
ipcMain.on('select-run-mode', async (event, mode) => {
  console.log('Mode selected:', mode);
  selectedMode = mode;
  
  // Set environment variable based on selection
  if (mode === 'localhost') {
    process.env.ELECTRON_USE_LOCALHOST = 'true';
    updateSplashStatus('Starting in development mode...');
    
    // Open web browser to localhost:3000
    setTimeout(() => {
      shell.openExternal('http://localhost:3000');
      console.log('Opening web browser to http://localhost:3000');
    }, 2000); // Wait a bit for React dev server to start
  } else {
    process.env.ELECTRON_USE_LOCALHOST = 'false';
    updateSplashStatus('Starting in production mode...');
    
    // Check if build exists, if not, build it
    const buildPath = path.join(__dirname, '..', 'build', 'index.html');
    if (!fs.existsSync(buildPath)) {
      updateSplashStatus('Building React app...');
      console.log('Build not found, building React app...');
      // Note: Building from Electron is complex, so we'll just try to load
      // The batch file should handle building before launching Electron
    }
  }
  
  // Resolve the mode selection promise
  if (modeSelectionResolve) {
    modeSelectionResolve(mode);
  }
  
  // Start the application initialization
  initializeApplication();
});

// Initialize application after mode selection
async function initializeApplication() {
  try {
    // Check if backend is already running
    const platform = os.platform();
    const curlCmd = platform === 'win32' ? 'curl -s http://localhost:5000/api/health' : 'curl -s http://localhost:5000/api/health';
    
    updateSplashStatus('Checking backend connection...');
    
    exec(curlCmd, async (error, stdout) => {
      if (error || !stdout || !stdout.trim()) {
        // Backend not running - start it
        console.log('Backend not detected, starting backend...');
        updateSplashStatus('Starting backend server...');
        try {
          await startBackendProcess();
          // Wait for backend to be ready
          updateSplashStatus('Waiting for backend to be ready...');
          const backendReady = await waitForBackend(30);
          if (!backendReady) {
            console.log('Backend may still be starting - continuing anyway');
          }
          updateSplashStatus('Backend ready!');
        } catch (backendError) {
          console.error('Error starting backend:', backendError);
          updateSplashStatus('Backend startup error - continuing anyway');
          // Continue anyway - user can start backend manually
        }
      } else {
        console.log('Backend is already running');
        updateSplashStatus('Backend connected');
      }
      
      // Now create main window
      try {
        updateSplashStatus('Loading application...');
        createWindow();
      } catch (windowError) {
        console.error('Error creating window:', windowError);
        closeSplashWindow();
      }
    });
  } catch (error) {
    console.error('Error in startup sequence:', error);
    closeSplashWindow();
  }
}

// This method will be called when Electron has finished initialization
app.whenReady().then(async () => {
  console.log('Electron app ready');
  
  // Create application menu
  createMenu();
  
  // Create splash screen FIRST - before anything else
  createSplashWindow();
  
  // Wait a moment for splash to show
  await new Promise(resolve => setTimeout(resolve, 300));
  
  // Wait for user to select mode
  await waitForModeSelection();

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

// File picker: show dialog, read files, send to renderer (works in Electron when HTML input fails)
ipcMain.on('open-file-dialog', async (event, { slots = 10 } = {}) => {
  const win = mainWindow && !mainWindow.isDestroyed() ? mainWindow : BrowserWindow.getFocusedWindow();
  if (!win) return;
  const { canceled, filePaths } = await dialog.showOpenDialog(win, {
    properties: ['openFile', 'multiSelections'],
    filters: [{ name: 'Supported', extensions: ['txt', 'md', 'json', 'csv', 'log', 'py', 'js', 'html', 'css', 'xml', 'yml', 'yaml', 'docx'] }]
  });
  if (canceled || !filePaths || filePaths.length === 0) return;
  const toProcess = filePaths.slice(0, Math.max(1, slots));
  const readOne = async (p) => {
    try {
      const stat = fs.statSync(p);
      if (stat.size > 1024 * 1024) return null;
      const ext = path.extname(p).toLowerCase().slice(1);
      if (ext === 'doc') return null;
      let content;
      if (ext === 'docx' && mammoth) {
        const r = await mammoth.extractRawText({ path: p });
        content = r.value;
      } else if (ext === 'docx') {
        return null;
      } else {
        content = fs.readFileSync(p, 'utf-8');
      }
      return { name: path.basename(p), content };
    } catch (err) {
      return null;
    }
  };
  const results = await Promise.allSettled(toProcess.map(readOne));
  const files = results.filter(r => r.status === 'fulfilled' && r.value).map(r => r.value);
  if (files.length && win && !win.isDestroyed()) win.webContents.send('files-selected', { files });
});

// Security: Prevent new window creation
app.on('web-contents-created', (event, contents) => {
  contents.on('new-window', (event, navigationUrl) => {
    event.preventDefault();
    require('electron').shell.openExternal(navigationUrl);
  });
});
