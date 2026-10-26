@echo off
title Munim Ji One-Click Launcher
echo ====================================================
echo Starting Munim Ji Backend + Frontend Web Server...
echo ====================================================

echo 1. Starting Backend API (Port 8000)...
start "Munim Ji Backend Server" cmd /k "py -3 "%~dp0standalone_backend.py""

timeout /t 2 /nobreak >nul

echo 2. Starting Frontend Web App (Port 8080)...
start "Munim Ji Web App" cmd /k "py -3 "%~dp0serve_web.py""

timeout /t 2 /nobreak >nul

echo 3. Opening Local Web App in Browser...
start http://localhost:8080

echo ====================================================
echo Both Servers are RUNNING!
echo PC Link   : http://localhost:8080
echo Check backend window for Network URL
echo ====================================================
pause
