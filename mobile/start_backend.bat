@echo off
title Munim Ji FastAPI Backend (Port 8000)
echo ====================================================
echo  Starting Munim Ji AI Backend (FastAPI + Uvicorn)
echo  URL: http://192.168.0.104:8000 (Local: http://127.0.0.1:8000)
echo ====================================================
cd /d "C:\Users\user\Desktop\ANTIGRAVTY"
"C:\Users\user\Desktop\ANTIGRAVTY\.venv\Scripts\uvicorn.exe" app.main:app --host 0.0.0.0 --port 8000 --reload
pause
