@echo off
title AL-Chat Backend
color 0B
cd /d "%~dp0\..\Backend"

echo ========================================
echo   AL-Chat Backend Server
echo ========================================
echo.
echo Starting backend on http://localhost:5000
echo.

python main.py

if errorlevel 1 (
    echo.
    echo [ERROR] Backend failed to start
    echo.
    pause
)
