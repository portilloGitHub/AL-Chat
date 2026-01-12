// Preload script for Electron
// This runs in a context that has access to both DOM and Node.js APIs
// but is isolated from the main process

const { contextBridge, ipcRenderer } = require('electron');

// Expose protected methods that allow the renderer process to use
// APIs from the main process
contextBridge.exposeInMainWorld('electronAPI', {
  // Add any Electron APIs you need here
  platform: process.platform,
  versions: {
    node: process.versions.node,
    chrome: process.versions.chrome,
    electron: process.versions.electron
  },
  // Backend restart functionality
  restartBackend: () => ipcRenderer.send('restart-backend'),
  onBackendRestarted: (callback) => ipcRenderer.on('backend-restarted', callback),
  onBackendRestartError: (callback) => ipcRenderer.on('backend-restart-error', (event, error) => callback(error))
});
