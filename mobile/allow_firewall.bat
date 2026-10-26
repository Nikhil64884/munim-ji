@echo off
title Allow Munim Ji in Windows Firewall
echo ====================================================
echo Adding Firewall rules for Port 8000 and 8080...
echo ====================================================

netsh advfirewall firewall delete rule name="MunimJi Web" >nul 2>&1
netsh advfirewall firewall add rule name="MunimJi Web" dir=in action=allow protocol=TCP localport=8080,8000

echo ====================================================
if %errorlevel% EQU 0 (
    echo SUCCESS: Ports 8080 and 8000 are now OPEN!
    echo Phone se http://192.168.1.35:8080 ab khul jayega.
) else (
    echo FAILED: Please make sure you Right-click and choose 'Run as administrator'!
)
echo ====================================================
pause
