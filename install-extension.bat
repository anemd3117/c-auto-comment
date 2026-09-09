@echo off
setlocal EnableExtensions
chcp 65001 >nul

set "INSTALLER=%~dp0scripts\install.ps1"

if not exist "%INSTALLER%" (
    echo [ERROR] Installer script not found: %INSTALLER%
    pause
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%INSTALLER%"
if errorlevel 1 (
    echo.
    pause
    exit /b 1
)

echo.
pause
exit /b 0
