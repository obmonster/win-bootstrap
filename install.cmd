@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0"

fltmc >nul 2>&1
if errorlevel 1 (
    echo Requesting administrator privileges...
    set "WIN_BOOTSTRAP_CMD=%~f0"
    powershell.exe -NoProfile -Command "Start-Process -FilePath $env:WIN_BOOTSTRAP_CMD -Verb RunAs"
    exit /b
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1"
set "EXIT_CODE=%ERRORLEVEL%"

echo.
if not "%EXIT_CODE%"=="0" echo Initialization completed with errors. Check the logs directory.
pause
exit /b %EXIT_CODE%
