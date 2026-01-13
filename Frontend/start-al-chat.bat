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
if errorlevel 1 (
    echo [INFO] Backend not detected
    echo [INFO] Splash screen will show first, then backend will start automatically
    echo.
    goto :launch
)

echo [OK] Backend is already running
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
