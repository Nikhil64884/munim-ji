@echo off
title Munim Ji - Apply 16 Production Backend Fixes
echo ====================================================
echo Running Auto-Patcher on C:\Users\user\Desktop\ANTIGRAVTY...
echo ====================================================

py -3 "%~dp0apply_production_fixes.py"

echo ====================================================
echo Patching finished!
echo Now commit and push to GitHub:
echo   cd C:\Users\user\Desktop\ANTIGRAVTY
echo   git add .
echo   git commit -m "Apply critical production security and stability fixes"
echo   git push origin main
echo ====================================================
pause
