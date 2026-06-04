@echo off
setlocal
chcp 65001 >nul
title ComfyUI Launcher by L.'.L.'.

cd /d "%~dp0"
cd ..

set "UV_CACHE_DIR=.cache\uv"
set "UV_NO_PROGRESS=1"
set "PYTHON_EXE=comfy_env\Scripts\python.exe"

set "STABLE_FLAG="

powershell -Command "Write-Host '============================================================' -ForegroundColor Green"
powershell -Command "Write-Host '                  ComfyUI Updater' -ForegroundColor Green"
powershell -Command "Write-Host '============================================================' -ForegroundColor Green"
echo.
powershell -Command "Write-Host 'Stable version:' -ForegroundColor Yellow -NoNewline; Write-Host '   Switches to the latest stable tag (v*). Recommended for everyday use.' -ForegroundColor White"
powershell -Command "Write-Host '                     More reliable, fewer breaking changes.' -ForegroundColor White"
echo.
powershell -Command "Write-Host 'Nightly version:' -ForegroundColor Yellow -NoNewline; Write-Host '  Stays on the latest master branch (cutting edge).' -ForegroundColor White"
powershell -Command "Write-Host '                     Includes newest features, may be unstable.' -ForegroundColor White"
echo.
powershell -Command "Write-Host 'Choose update mode:' -ForegroundColor Cyan"
echo "  1 - Stable (recommended)"
echo "  2 - Nightly (bleeding edge)"
echo.

choice /c 12 /n /m "Enter 1 or 2: "
if errorlevel 2 (
    echo.
    powershell -Command "Write-Host '>> Nightly mode selected (master branch)' -ForegroundColor Yellow"
    set "STABLE_FLAG="
) else (
    echo.
    powershell -Command "Write-Host '>> Stable mode selected (latest tag)' -ForegroundColor Yellow"
    set "STABLE_FLAG=--stable"
)

echo.
powershell -Command "Write-Host 'Starting update...' -ForegroundColor Green"
%PYTHON_EXE% update\update.py ComfyUI %STABLE_FLAG%

if "%~1"=="" pause