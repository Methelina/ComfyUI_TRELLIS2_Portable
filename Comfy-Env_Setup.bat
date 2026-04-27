@echo off
chcp 65001 >nul
title ComfyUI-Env Setup – Universal Installer for isolated environments

:: ==========================================================
:: TRELLIS2 Portable – Interactive installer for comfy-env nodes
:: ==========================================================
:: Version: 1.2.0
:: Author:  Soror L.'.L.'.
:: Updated: 2026-04-27
::
:: Patchnote v1.2.0 (By Soror L.'.L.'):
::   [+] Added full portability isolation block
::       - PIXI_HOME, PIXI_ENV_DIR, PIXI_CACHE_DIR
::       - RATTLER_CACHE_DIR, UV_CACHE_DIR, HF_HOME
::       - PIXI_NO_VERSION_CHECK
::   [*] Now all Pixi data stays inside project folder
::   [*] Fixed potential "may was unexpected" errors
::
:: Patchnote v1.1.0 (By Soror L.'.L.'):
::   [+] Initial release with interactive node setup
:: ==========================================================

setlocal enabledelayedexpansion

cd /d "%~dp0"

:: ==========================================================
:: === PORTABILITY ISOLATION BLOCK ===
:: ==========================================================
set "SCRIPT_DIR=%~dp0"
set "PIXI_HOME=%SCRIPT_DIR%.pixi_home"
set "PIXI_ENV_DIR=%SCRIPT_DIR%.pixi_envs"
set "PIXI_CACHE_DIR=%SCRIPT_DIR%.cache\pixi"
set "RATTLER_CACHE_DIR=%SCRIPT_DIR%.cache\rattler"
set "UV_CACHE_DIR=%SCRIPT_DIR%.cache\uv"
set "HF_HOME=%SCRIPT_DIR%.cache\huggingface"
set "HF_HUB_DOWNLOAD_TIMEOUT=60"
set "PIXI_NO_VERSION_CHECK=1"
:: ==========================================================

:: === 1. Check and add Pixi (Bin) to PATH ===
if exist "%~dp0Bin\pixi.exe" (
    set "PATH=%~dp0Bin;%PATH%"
    echo [INFO] Pixi found in Bin and added to PATH.
) else (
    echo [WARN] Pixi not found in Bin. Isolated environments may fail.
    echo [INFO] Please ensure pixi.exe is placed in the "Bin" folder.
    echo.
)

:: === 2. Activate main comfy_env ===
if not exist "%~dp0comfy_env\Scripts\activate.bat" (
    echo [ERROR] comfy_env not found. Please run Trellis2_portable.ps1 first.
    pause
    exit /b 1
)
call "%~dp0comfy_env\Scripts\activate.bat"
if errorlevel 1 (
    echo [ERROR] Failed to activate comfy_env.
    pause
    exit /b 1
)
echo [INFO] Virtual environment comfy_env activated.
echo.

:: === 3. Ask user for target directory ===
:ask
set "TARGET_DIR="
set /p "TARGET_DIR=Enter full or relative path to node folder (e.g.,  D:\ComfyUI\custom_nodes\ComfyUI-GeometryPack): "
if "%TARGET_DIR%"=="" (
    echo [ERROR] No path entered. Please try again.
    goto ask
)

:: Remove surrounding quotes if present
set "TARGET_DIR=%TARGET_DIR:"=%"

:: Resolve relative path to absolute using cd trick
pushd "%TARGET_DIR%" 2>nul
if errorlevel 1 (
    echo [ERROR] Folder "%TARGET_DIR%" does not exist.
    goto ask
)
set "TARGET_DIR=%CD%"
popd

:: === 4. Check for install.py or setup.py ===
set "INSTALL_SCRIPT="
if exist "%TARGET_DIR%\install.py" (
    set "INSTALL_SCRIPT=%TARGET_DIR%\install.py"
) else if exist "%TARGET_DIR%\setup.py" (
    set "INSTALL_SCRIPT=%TARGET_DIR%\setup.py"
) else (
    echo [ERROR] Neither install.py nor setup.py found in "%TARGET_DIR%"
    echo.
    goto ask
)

:: === 5. Run the script ===
echo.
echo [INFO] Running %INSTALL_SCRIPT% in isolated environment...
pushd "%TARGET_DIR%"
python "%INSTALL_SCRIPT%"
set "EXIT_CODE=%errorlevel%"
popd

if %EXIT_CODE% neq 0 (
    echo [ERROR] Script failed with code %EXIT_CODE%
) else (
    echo [SUCCESS] Installation completed.
)

echo.
pause