@echo off
title Replace Backend with Security Fixes
echo ====================================================
echo Copying fixes from munim_ji_security_fixes to ANTIGRAVTY...
echo ====================================================

if not exist "C:\Users\user\Desktop\munim_ji_security_fixes" (
    echo ERROR: Folder C:\Users\user\Desktop\munim_ji_security_fixes NOT found!
    pause
    exit /b 1
)

robocopy "C:\Users\user\Desktop\munim_ji_security_fixes" "C:\Users\user\Desktop\ANTIGRAVTY" /E /IS /IT /np /nfl /ndl

echo ====================================================
echo SUCCESS: All files replaced successfully in ANTIGRAVTY!
echo ====================================================
pause
