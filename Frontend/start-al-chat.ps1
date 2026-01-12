# AL-Chat Launcher Script for PowerShell
Write-Host "========================================" -ForegroundColor Green
Write-Host "  AL-Chat Desktop Application" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Check if Node.js is installed
try {
    $null = Get-Command node -ErrorAction Stop
    Write-Host "[OK] Node.js found" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Node.js is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Node.js from https://nodejs.org/" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if dependencies are installed
if (-not (Test-Path "node_modules")) {
    Write-Host "[INFO] Installing dependencies..." -ForegroundColor Yellow
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Failed to install dependencies" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# Check if backend is running
Write-Host "[INFO] Checking backend connection..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:5000/api/health" -TimeoutSec 2 -ErrorAction Stop
    Write-Host "[OK] Backend is running" -ForegroundColor Green
} catch {
    Write-Host "[WARNING] Backend not detected on port 5000" -ForegroundColor Yellow
    Write-Host "[INFO] Starting Electron app anyway..." -ForegroundColor Yellow
    Write-Host "[NOTE] Make sure to start the backend: cd Backend && python main.py" -ForegroundColor Cyan
    Write-Host ""
}

# Start Electron app
Write-Host "[INFO] Starting AL-Chat..." -ForegroundColor Green
Write-Host ""
npm run electron-dev

Read-Host "Press Enter to exit"
