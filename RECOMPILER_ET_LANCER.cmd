@echo off
setlocal
cd /d "%~dp0"
if defined VSCMD_VER goto build
if not exist "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" goto build
for /f "usebackq tokens=*" %%I in (`"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "MS_VS=%%I"
if defined MS_VS call "%MS_VS%\Common7\Tools\VsDevCmd.bat" -arch=x64 -host_arch=x64
:build
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0rebuild.ps1"
if errorlevel 1 (
 echo.
 echo Echec : consultez compilation_fix.log dans ce dossier.
 pause
 exit /b 1
)
endlocal
