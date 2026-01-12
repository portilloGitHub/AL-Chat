// Preload script for Electron
// This runs in a context that has access to both DOM and Node.js APIs
// but is isolated from the main process

const { contextBridge } = require('electron');

// Expose protected methods that allow the renderer process to use
// APIs from the main process
contextBridge.exposeInMainWorld('electronAPI', {
  // Add any Electron APIs you need here
  platform: process.platform,
  versions: {
    node: process.versions.node,
    chrome: process.versions.chrome,
    electron: process.versions.electron
  }
});
