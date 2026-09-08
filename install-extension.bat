@echo off
chcp 65001 >nul
echo ====================================================
echo [Auto Comment] VS Code 확장 프로그램 자동 설치 스크립트
echo ====================================================

set VSIX_FILE=%~dp0auto-comment-extension\auto-comment-after-run-0.0.6.vsix

if not exist "%VSIX_FILE%" (
    echo [에러] 확장 파일(%VSIX_FILE%)을 찾을 수 없습니다.
    pause
    exit /b 1
)

echo VS Code 확장을 설치합니다...
call code --install-extension "%VSIX_FILE%" --force

if %ERRORLEVEL% equ 0 (
    echo.
    echo [성공] Auto Comment 확장이 성공적으로 설치되었습니다!
    echo VS Code를 다시 시작하거나 창을 새로고침(Ctrl+R)하세요.
) else (
    echo.
    echo [실패] 설치 중 오류가 발생했습니다. 'code' 명령어가 환경변수 PATH에 등록되어 있는지 확인하세요.
)

pause
