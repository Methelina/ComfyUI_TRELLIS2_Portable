@echo off
chcp 65001 >nul
title TRELLIS2 Portable Launcher by L.'.L.'.
cd /d "%~dp0"

:: ==========================================================
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

:: === Environment activation and ComfyUI launch
call ".\comfy_env\Scripts\activate.bat" && python -s -W ignore::FutureWarning ComfyUI\main.py --normalvram --cache-lru 6 --windows-standalone-build --listen --enable-cors-header --port %COMFYUI_PORT%
::  --use-flash-attention
:: --fast fp16_accumulation

pause