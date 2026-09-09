@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

echo ====================================================
echo [Auto Comment] Portable installer v0.0.8
echo ====================================================

set "ROOT=%~dp0"
set "BOOTSTRAP=%ROOT%scripts\bootstrap.ps1"
set "EXT_DIR=%ROOT%auto-comment-extension"
set "VSIX=%EXT_DIR%\auto-comment-after-run-0.0.8.vsix"

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

set "CODE_CMD=code"
where code >nul 2>&1
if errorlevel 1 (
    if exist "%LOCALAPPDATA%\Programs\Microsoft VS Code\bin\code.cmd" (
        set "CODE_CMD=%LOCALAPPDATA%\Programs\Microsoft VS Code\bin\code.cmd"
    ) else if exist "%ProgramFiles%\Microsoft VS Code\bin\code.cmd" (
        set "CODE_CMD=%ProgramFiles%\Microsoft VS Code\bin\code.cmd"
    ) else (
        echo [ERROR] VS Code CLI was not found after installation.
        goto :fail
    )
)

if not exist "%VSIX%" (
    echo [INFO] Building VSIX package from source...
    pushd "%EXT_DIR%"
    call npx --yes @vscode/vsce package --out "auto-comment-after-run-0.0.8.vsix"
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
echo [READY] Auto Comment v0.0.8 is installed.
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
