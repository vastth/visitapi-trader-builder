@echo off
setlocal
cd /d "%~dp0"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0deploy_fence_proof_of_work.ps1" %*
set "exitCode=%ERRORLEVEL%"

echo.
if "%exitCode%"=="0" (
    echo Deployment finished successfully.
) else (
    echo Deployment failed with exit code %exitCode%.
)

pause
exit /b %exitCode%