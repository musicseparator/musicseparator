@echo off
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0midi\install.ps1" -Drums
if errorlevel 1 (
 pause
 exit /b 1
)
pause
