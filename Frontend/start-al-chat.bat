@echo off
title AL-Chat Launcher
color 0A
setlocal enabledelayedexpansion

echo ========================================
echo   AL-Chat Desktop Application
echo ========================================
echo.
echo [DEBUG] Script started
echo.

cd /d "%~dp0"

where node >nul 2>nul
if errorlevel 1 goto :no_node

echo [OK] Node.js found
echo.

if not exist "node_modules" goto :install_deps

call npm list concurrently >nul 2>nul
if errorlevel 1 goto :install_electron

echo [OK] Dependencies already installed
echo.
goto :start_backend

:install_deps
echo [INFO] Installing dependencies (this may take a minute)...
call npm install
if errorlevel 1 goto :install_error
echo [OK] Dependencies installed
echo.
goto :start_backend

:install_electron
echo [INFO] Installing missing Electron dependencies...
call npm install concurrently wait-on electron electron-is-dev --save-dev
if errorlevel 1 goto :install_error
echo [OK] Dependencies installed
echo.
goto :start_backend

:start_backend
echo [INFO] Checking backend connection...
curl -s http://localhost:5000/api/health >nul 2>nul
if not errorlevel 1 (
    echo [OK] Backend is already running
    echo.
    goto :launch
)

echo [INFO] Backend not detected. Starting backend...
if exist "%~dp0\start-backend.bat" (
    start "AL-Chat Backend" cmd /k "%~dp0\start-backend.bat"
) else (
    start "AL-Chat Backend" cmd /k "cd /d ""%~dp0\..\Backend"" & python main.py"
)
echo [INFO] Waiting for backend to be ready (up to 30 seconds)...
set WAIT_COUNT=0
:wait_backend
curl -s http://localhost:5000/api/health >nul 2>nul
if not errorlevel 1 goto backend_ready
set /a WAIT_COUNT+=1
if %WAIT_COUNT% geq 30 goto :launch
timeout /t 1 /nobreak >nul
goto wait_backend
:backend_ready
echo [OK] Backend is ready
echo.
goto :launch

:launch
echo [INFO] Starting AL-Chat...
echo [INFO] Mode selection will appear in the splash screen
echo.
call npm run electron-dev
set EXIT_CODE=%ERRORLEVEL%

REM Exit immediately when Electron closes
exit /b %EXIT_CODE%

:no_node
echo [ERROR] Node.js is not installed or not in PATH
echo Please install Node.js from https://nodejs.org/
pause
exit /b 1

:install_error
echo [ERROR] Failed to install dependencies
pause
exit /b 1

:launch_error
echo [ERROR] Failed to start AL-Chat
echo.
echo Check the error messages above for details
echo.
pause
exit /b 1
