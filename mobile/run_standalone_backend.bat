@echo off
title Munim Ji Standalone Backend Server (Port 8000)
echo ====================================================
echo Starting Munim Ji Backend API on 0.0.0.0:8000...
echo ====================================================
py -3 "%~dp0standalone_backend.py"
if errorlevel 1 (
    python "%~dp0standalone_backend.py"
)
pause
