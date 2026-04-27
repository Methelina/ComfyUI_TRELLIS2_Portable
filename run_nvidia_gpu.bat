@echo off
chcp 65001 >nul
title TRELLIS2 Portable Launcher by L.'.L.'.
:: ==========================================================
:: TRELLIS2 Portable Launcher
:: ==========================================================
:: Version: 1.2.0
:: Author:  Soror L.'.L.'.
:: Updated: 2026-04-27
::
:: Patchnote v1.2.0 (By Soror L.'.L.'.):
::   [+] FULL ISOLATION: all runtime data inside project folder
::       - PIXI_HOME, PIXI_ENV_DIR, PIXI_CACHE_DIR
::       - RATTLER_CACHE_DIR, UV_CACHE_DIR, HF_HOME
::       - COMFY_CACHE_DIR (--temp-directory)
::   [+] Added PIXI_NO_VERSION_CHECK to prevent auto-updates
::   [*] Ensured no writes to C:\Users\... or %LOCALAPPDATA%
::   [*] Now fully portable – can be moved to any drive/folder
::
:: Patchnote v1.1.0 (By Soror L.'.L.'.):
::   [+] Added Pixi support for isolated environments (comfy-env)
::   [+] Added automatic PATH update for .\Bin\pixi.exe
::   [+] Added [INFO]/[WARN] messages for Pixi availability
::   [*] Preserved all original environment variables and startup logic
::
:: Patchnote v1.0.0 (By Soror L.'.L.'.):
::   [+] Initial release
:: ==========================================================
cd /d "%~dp0"

:: ==========================================================
:: ==========================================================
echo  ======================================================
echo.
echo   ██▓        ██▓    ██▓        ██▓
echo  ▓██▒              ▓██▒
echo  ▒██░              ▒██░
echo  ▒██░              ▒██░
echo  ░██████▒ ██▓  ██▓ ░██████▒ ██▓  ██▓
echo  ░ ▒░▓  ░ ▒▓▒  ▒▓▒ ░ ▒░▓  ░ ▒▓▒  ▒▓▒
echo  ░ ░ ▒  ░ ░▒   ░▒  ░ ░ ▒  ░ ░▒   ░▒
echo    ░ ░    ░    ░     ░ ░    ░    ░
echo      ░  ░  ░    ░      ░  ░  ░    ░
echo.
echo  ======================================================
echo    TRELLIS2 Portable ComfyUI Launcher by Soror L.'.L.'.
echo.
:: ==========================================================
:: === Pixi set PATH ===
if exist "%~dp0Bin\pixi.exe" (
    set "PATH=%~dp0Bin;%PATH%"
    echo [INFO] Pixi found in Bin and added to PATH.
) else (
    echo "[WARN] Pixi not found in Bin. Isolated environments (comfy-env) may fail."
    echo "[INFO] Please ensure pixi.exe is placed in the \"Bin\" folder next to this launcher."
)
:: ============== ENV VAR SET ==============================
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
set "TMP=%SCRIPT_DIR%.cache\tmp"
set "TEMP=%SCRIPT_DIR%.cache\tmp"
set "COMFY_CE_BUILD_BASE=%SCRIPT_DIR%.cache\ce"
set "BUILD_DIR=%SCRIPT_DIR%.cache\build_dir"
if not exist "%TMP%" mkdir "%TMP%"
if not exist "%COMFY_CE_BUILD_BASE%" mkdir "%COMFY_CE_BUILD_BASE%"
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
:: ==========================================================
set COMFY_CACHE_DIR=%SCRIPT_DIR%.cache\ComfyUI_Cache
if not exist "%COMFY_CACHE_DIR%" mkdir "%COMFY_CACHE_DIR%"
:: ==========================================================

:: === Proxy for all HTTP/HTTPS requests (including HF, pip, requests, urllib, etc.). Uncomment it if you use a proxy for internet connection
:: set HTTP_PROXY=http://127.0.0.1:18080 
:: set HTTPS_PROXY=http://127.0.0.1:18080 
:: set NO_PROXY=localhost,127.0.0.1,::1

:: === eVAR and HF ===
:: set HF_ENDPOINT=https://hf-mirror.com   
set HF_HUB_DOWNLOAD_TIMEOUT=60
:: set HF_HUB_ENABLE_HF_TRANSFER=1 

:: === CPU and threads for 2x Xeon E5-2697A v4 ===
set NUMEXPR_MAX_THREADS=32 
set OMP_NUM_THREADS=32
set MKL_NUM_THREADS=32
set MKL_DYNAMIC=TRUE
set MKL_NUMA_DOMAIN=ALL

:: === Load acceleration and GPU ===
set SAFETENSORS_FAST_GPU=1
set CUDA_MODULE_LOADING=LAZY
set TF_ENABLE_ONEDNN_OPTS=1

:: === PyTorch memory: tuned for 12 GB VRAM TITAN V ===
set PYTORCH_CUDA_ALLOC_CONF=garbage_collection_threshold:0.8,expandable_segments:True,max_split_size_mb:128

:: === GPU ===
set CUDA_VISIBLE_DEVICES=0

:: === ComfyUI port ===
set COMFYUI_PORT=8085

:: === Attention ===
set XFORMERS_MORE_DETAILS=1
set FLASH_ATTENTION_FORCE_OPTIM=1

:: === Keep ComfyUI-Trellis2-GGUF updated === 
:: https://github.com/Aero-Ex/ComfyUI-Trellis2-GGUF 
::
:: echo [INFO] Updating ComfyUI-Trellis2-GGUF...
::  cd /d "%~dp0ComfyUI\custom_nodes\ComfyUI-Trellis2-GGUF"
::  if exist ".git" (
::     git pull origin main
:: ) else (
::     echo [WARN] ComfyUI-Trellis2-GGUF is not a Git repository — skipping update.
:: )
:: cd /d "%~dp0"
:: echo [INFO] ComfyUI-Trellis2-GGUF update attempt completed.
:: echo.

:: === Environment activation and ComfyUI launch (fixed: quoted temp dir, removed inline comments) ===
call ".\comfy_env\Scripts\activate.bat" && python -s -W ignore::FutureWarning ComfyUI\main.py --normalvram --cache-lru 6 --windows-standalone-build --listen --temp-directory "%COMFY_CACHE_DIR%" --enable-cors-header --port %COMFYUI_PORT% 

:: Optional flags (uncomment if needed):
:: --use-flash-attention
:: --fast fp16_accumulation

pause