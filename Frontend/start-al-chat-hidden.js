/**
 * AL-Chat Hidden Launcher (Node.js)
 * Runs the application without showing a terminal window
 * 
 * This script can be compiled to an .exe using pkg or nexe
 * Or run directly: node start-al-chat-hidden.js
 */

const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

// Hide console window on Windows
if (process.platform === 'win32') {
  // Try to hide the console window
  try {
    const kernel32 = require('ffi-napi').Library('kernel32', {
      'FreeConsole': ['bool', []]
    });
    kernel32.FreeConsole();
  } catch (e) {
    // If ffi-napi is not available, continue without hiding
    // The VBScript launcher should be used instead
  }
}

// Get the directory where this script is located
const scriptDir = __dirname;
const batchFile = path.join(scriptDir, 'start-al-chat.bat');

// Check if batch file exists
if (!fs.existsSync(batchFile)) {
  console.error('Error: Could not find start-al-chat.bat');
  process.exit(1);
}

// Run the batch file
const child = spawn(batchFile, [], {
  cwd: scriptDir,
  shell: true,
  stdio: 'ignore' // Hide all output
});

child.on('exit', (code) => {
  process.exit(code || 0);
});

child.on('error', (error) => {
  console.error('Error starting application:', error);
  process.exit(1);
});
