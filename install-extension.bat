@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

echo ====================================================
echo [Auto Comment] Portable installer v0.0.9
echo ====================================================

set "ROOT=%~dp0"
set "BOOTSTRAP=%ROOT%scripts\bootstrap.ps1"
set "EXT_DIR=%ROOT%auto-comment-extension"
set "VSIX=%EXT_DIR%\auto-comment-after-run-0.0.9.vsix"

if not exist "%BOOTSTRAP%" (
    echo [ERROR] Bootstrap script not found: %BOOTSTRAP%
    goto :fail
)

echo [INFO] Checking and installing required development tools...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%BOOTSTRAP%" -Components All
if errorlevel 1 (
    echo [ERROR] Dependency bootstrap failed.
    goto :fail
)

set "CODE_CMD="

for /f "delims=" %%I in ('where code.cmd 2^>nul') do (
    if not defined CODE_CMD set "CODE_CMD=%%~fI"
)

if not defined CODE_CMD if exist "%LOCALAPPDATA%\Programs\Microsoft VS Code\bin\code.cmd" (
    set "CODE_CMD=%LOCALAPPDATA%\Programs\Microsoft VS Code\bin\code.cmd"
)

if not defined CODE_CMD if exist "%ProgramFiles%\Microsoft VS Code\bin\code.cmd" (
    set "CODE_CMD=%ProgramFiles%\Microsoft VS Code\bin\code.cmd"
)

if not defined CODE_CMD if exist "%ProgramFiles(x86)%\Microsoft VS Code\bin\code.cmd" (
    set "CODE_CMD=%ProgramFiles(x86)%\Microsoft VS Code\bin\code.cmd"
)

if not defined CODE_CMD (
    echo [ERROR] VS Code CLI was not found after installation.
    goto :fail
)

echo [OK] VS Code CLI resolved: !CODE_CMD!

if not exist "%VSIX%" (
    echo [INFO] Building VSIX package from source...
    pushd "%EXT_DIR%"
    call npx --yes @vscode/vsce package --out "auto-comment-after-run-0.0.9.vsix"
    set "PKG_EXIT=!ERRORLEVEL!"
    popd
    if not "!PKG_EXIT!"=="0" (
        echo [ERROR] VSIX packaging failed with exit code !PKG_EXIT!.
        goto :fail
    )
)

echo [INFO] Installing extension: %VSIX%
call "%CODE_CMD%" --install-extension "%VSIX%" --force
if errorlevel 1 (
    echo [ERROR] VS Code extension installation failed.
    goto :fail
)

echo.
echo [READY] Auto Comment v0.0.9 is installed.
echo [INFO] Restart VS Code or run "Developer: Reload Window".
echo.
pause
exit /b 0

:fail
echo.
echo [FAILED] Installation did not complete.
echo.
pause
exit /b 1
