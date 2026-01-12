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
if errorlevel 1 goto :start_backend_server

echo [OK] Backend is already running
echo.
goto :launch

:start_backend_server
echo [INFO] Backend not detected - starting backend server...
echo.

REM Check if Python 3.11 is available (preferred for stability)
py -3.11 --version >nul 2>nul
if not errorlevel 1 (
    set PYTHON_CMD=py -3.11
    echo [OK] Python 3.11 found
    goto :python_ok
)

REM Fallback to default Python
where python >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Python is not installed or not in PATH
    echo [ERROR] Cannot start backend server
    echo [INFO] Please install Python 3.11 or start the backend manually
    echo.
    pause
    exit /b 1
)
set PYTHON_CMD=python

:python_ok

REM Check if backend directory exists
if not exist "%~dp0\..\Backend\main.py" (
    echo [ERROR] Backend main.py not found
    echo [ERROR] Expected location: %~dp0\..\Backend\main.py
    echo.
    pause
    exit /b 1
)

REM Check if Python dependencies are installed
echo [INFO] Checking Python dependencies...
cd /d "%~dp0\..\Backend"
%PYTHON_CMD% -c "import flask" >nul 2>nul
if errorlevel 1 (
    echo [INFO] Python dependencies not found - installing...
    echo [INFO] This may take a minute...
    echo.
    %PYTHON_CMD% -m pip install --upgrade -r requirements.txt
    if errorlevel 1 (
        echo [ERROR] Failed to install Python dependencies
        echo [ERROR] Please run manually: cd Backend && %PYTHON_CMD% -m pip install -r requirements.txt
        echo.
        pause
        exit /b 1
    )
    echo [OK] Python dependencies installed
    echo.
) else (
    REM Ensure OpenAI is up to date
    echo [INFO] Ensuring dependencies are up to date...
    %PYTHON_CMD% -m pip install --upgrade "openai>=1.40.0" >nul 2>nul
    echo [OK] Python dependencies ready
    echo.
)
cd /d "%~dp0"

REM Start backend in a new window (visible so user can see any errors)
echo [INFO] Starting backend server in new window...
echo [NOTE] Backend window will open - check it for any startup errors
echo.

REM Use /k to keep window open so errors are visible
start "AL-Chat Backend" cmd /k "cd /d %~dp0\..\Backend && title AL-Chat Backend && echo ======================================== && echo   AL-Chat Backend Server && echo ======================================== && echo. && echo Using: %PYTHON_CMD% && echo Starting backend on http://localhost:5000 && echo. && %PYTHON_CMD% main.py && echo. && echo Backend stopped. Press any key to close... && pause"

REM Give backend a moment to initialize
timeout /t 3 /nobreak >nul 2>nul

REM Wait for backend to be ready (max 30 seconds)
echo [INFO] Waiting for backend to start (this may take a few seconds)...
set WAIT_COUNT=0
:wait_for_backend
timeout /t 2 /nobreak >nul 2>nul
curl -s http://localhost:5000/api/health >nul 2>nul
if not errorlevel 1 (
    echo [OK] Backend is ready!
    echo.
    goto :launch
)
set /a WAIT_COUNT+=1
if !WAIT_COUNT! GEQ 15 (
    echo [WARNING] Backend is taking longer than expected to start
    echo [WARNING] Check the backend window for any error messages
    echo [INFO] Starting frontend anyway - backend may still be initializing
    echo [NOTE] If you see connection errors, check the backend window
    echo.
    goto :launch
)
echo [DEBUG] Waiting for backend... (!WAIT_COUNT!/15)
goto :wait_for_backend

:launch
echo [INFO] Starting AL-Chat...
echo [DEBUG] Running: npm run electron-dev
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
