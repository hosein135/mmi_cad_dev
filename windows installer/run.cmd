@echo off
REM Launcher for run.ps1. Double-click this file, or run:  run.cmd
REM The first run installs vfox, Vagrant, and VirtualBox, then starts Ubuntu.
REM A later run sees that setup and only starts the VM and ./run.sh.
REM Extra words are passed to run.sh, for example:  run.cmd max
REM Administrator rights are required for VirtualBox and the Vagrant MSI.

setlocal

set "SCRIPT_DIR=%~dp0"
set "PS1=%SCRIPT_DIR%run.ps1"

if not exist "%PS1%" (
    echo [run.cmd] ERROR: run.ps1 not found in:
    echo   %SCRIPT_DIR%
    pause
    exit /b 1
)

REM powershell is often missing from PATH, so other .cmd files fail with
REM "'powershell' is not recognized". Call the Windows PowerShell 5.1 exe directly.
set "PS_EXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if not exist "%PS_EXE%" set "PS_EXE=%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe"
if not exist "%PS_EXE%" set "PS_EXE=%SystemRoot%\SysWOW64\WindowsPowerShell\v1.0\powershell.exe"
if not exist "%PS_EXE%" (
    echo [run.cmd] ERROR: powershell.exe was not found.
    echo Expected:
    echo   %SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe
    pause
    exit /b 1
)

net session >nul 2>&1
if errorlevel 1 (
    echo [run.cmd] Administrator rights are required to install VirtualBox and Vagrant.
    echo [run.cmd] Approve the Windows prompt. The installer continues in that window.
    if "%~1"=="" (
        "%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    ) else (
        "%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs -ArgumentList '%*'"
    )
    if errorlevel 1 (
        echo [run.cmd] Administrator approval was cancelled.
        pause
        exit /b 1
    )
    exit /b 0
)

cd /d "%SCRIPT_DIR%"
"%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%PS1%" %*

echo.
echo ============================================================
echo  run.ps1 has finished. Press any key to close this window.
echo ============================================================
pause >nul
