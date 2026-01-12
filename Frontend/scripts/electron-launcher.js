/**
 * Electron Launcher Script
 * Manages React dev server and Electron, ensuring clean shutdown
 */
const { spawn } = require('child_process');
const http = require('http');
const path = require('path');

let reactServer = null;
let electronProcess = null;
let isShuttingDown = false;

// Cleanup function
function cleanup() {
  if (isShuttingDown) return;
  isShuttingDown = true;

  console.log('\n[INFO] Shutting down...');

  // Kill Electron if still running
  if (electronProcess && !electronProcess.killed && electronProcess.pid) {
    console.log('[INFO] Stopping Electron...');
    try {
      if (process.platform === 'win32') {
        // Windows: use taskkill
        spawn('taskkill', ['/F', '/T', '/PID', electronProcess.pid.toString()], {
          shell: true,
          stdio: 'ignore'
        });
      } else {
        electronProcess.kill('SIGTERM');
        setTimeout(() => {
          if (!electronProcess.killed && electronProcess.pid) {
            electronProcess.kill('SIGKILL');
          }
        }, 2000);
      }
    } catch (e) {
      // Ignore errors
    }
  }

  // Kill React server if still running
  if (reactServer && !reactServer.killed && reactServer.pid) {
    console.log('[INFO] Stopping React dev server...');
    try {
      if (process.platform === 'win32') {
        // Windows: use taskkill
        spawn('taskkill', ['/F', '/T', '/PID', reactServer.pid.toString()], {
          shell: true,
          stdio: 'ignore'
        });
      } else {
        reactServer.kill('SIGTERM');
        setTimeout(() => {
          if (!reactServer.killed && reactServer.pid) {
            reactServer.kill('SIGKILL');
          }
        }, 2000);
      }
    } catch (e) {
      // Ignore errors
    }
  }

  // Give processes a moment to terminate, then exit
  setTimeout(() => {
    process.exit(0);
  }, 1000);
}

// Handle process termination signals
process.on('SIGINT', cleanup);
process.on('SIGTERM', cleanup);
process.on('exit', () => {
  if (reactServer && !reactServer.killed) {
    reactServer.kill('SIGKILL');
  }
  if (electronProcess && !electronProcess.killed) {
    electronProcess.kill('SIGKILL');
  }
});

// Wait for React server to be ready
function waitForServer(url, maxAttempts = 60, interval = 1000) {
  return new Promise((resolve, reject) => {
    let attempts = 0;
    const check = () => {
      attempts++;
      const req = http.get(url, (res) => {
        if (res.statusCode === 200) {
          console.log('[OK] React dev server is ready!');
          resolve();
        } else {
          if (attempts < maxAttempts) {
            setTimeout(check, interval);
          } else {
            reject(new Error('React server did not become ready'));
          }
        }
      });
      req.on('error', () => {
        if (attempts < maxAttempts) {
          setTimeout(check, interval);
        } else {
          reject(new Error('React server did not become ready'));
        }
      });
      req.setTimeout(2000, () => {
        req.destroy();
        if (attempts < maxAttempts) {
          setTimeout(check, interval);
        } else {
          reject(new Error('React server timeout'));
        }
      });
    };
    check();
  });
}

// Start React dev server
console.log('[INFO] Starting React dev server...');
const frontendDir = path.resolve(__dirname, '..');

reactServer = spawn('npm', ['start'], {
  cwd: frontendDir,
  shell: true,
  env: { ...process.env, BROWSER: 'none' },
  stdio: 'inherit'
});

reactServer.on('error', (error) => {
  console.error('[ERROR] Failed to start React server:', error);
  process.exit(1);
});

reactServer.on('exit', (code) => {
  if (!isShuttingDown) {
    console.log(`[INFO] React server exited with code ${code}`);
    cleanup();
  }
});

// Wait for server, then start Electron
waitForServer('http://localhost:3000')
  .then(() => {
    console.log('[INFO] Starting Electron...');
    electronProcess = spawn('electron', ['.'], {
      cwd: frontendDir,
      shell: true,
      stdio: 'inherit'
    });

    // When Electron exits, clean up everything
    electronProcess.on('exit', (code) => {
      console.log(`[INFO] Electron exited with code ${code}`);
      cleanup();
    });

    electronProcess.on('error', (error) => {
      console.error('[ERROR] Electron error:', error);
      cleanup();
    });
  })
  .catch((error) => {
    console.error('[ERROR] Failed to start:', error.message);
    cleanup();
  });
