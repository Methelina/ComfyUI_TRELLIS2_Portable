@echo off
chcp 65001 >nul
title ComfyUI Launcher by L,',L,
cd /d "%~dp0"

:: ===========================================
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
echo  ===========================================
echo    ComfyUI Launcher by Soror L.'.L.'.
echo.

:: === Прокси для всех HTTP/HTTPS-запросов (включая HF, pip, requests, urllib и др.) ===
:: set HTTP_PROXY=http://127.0.0.1:18080
:: set HTTPS_PROXY=http://127.0.0.1:18080
:: set NO_PROXY=localhost,127.0.0.1,::1

:: === eVAR and HF ===
set HF_ENDPOINT=https://hf-mirror.com  
set HF_HUB_DOWNLOAD_TIMEOUT=60
set HF_HUB_ENABLE_HF_TRANSFER=1 

:: === CPU и потоки для 2x Xeon E5-2697A v4 ===
set NUMEXPR_MAX_THREADS=32 
set OMP_NUM_THREADS=32
set MKL_NUM_THREADS=32
set MKL_DYNAMIC=TRUE
set MKL_NUMA_DOMAIN=ALL

:: === Ускорение загрузки и GPU ===
set SAFETENSORS_FAST_GPU=1
set CUDA_MODULE_LOADING=LAZY
set TF_ENABLE_ONEDNN_OPTS=1

:: === Память PyTorch: адаптация под 12 ГБ VRAM TITAN V ===
set PYTORCH_CUDA_ALLOC_CONF=garbage_collection_threshold:0.8,expandable_segments:True,max_split_size_mb:128

:: === GPU ===
set CUDA_VISIBLE_DEVICES=0

:: === Attention ===
set XFORMERS_MORE_DETAILS=1
set FLASH_ATTENTION_FORCE_OPTIM=1

:: === Обновление ComfyUI-Trellis2 ===
echo [INFO] Updating ComfyUI-Trellis2...
cd /d "%~dp0ComfyUI\custom_nodes\ComfyUI-Trellis2"
if exist ".git" (
    git pull origin main
) else (
    echo [WARN] ComfyUI-Trellis2 is not a Git repository — skipping update.
)
cd /d "%~dp0"
echo [INFO] ComfyUI-Trellis2 update attempt completed.
echo.

".\comfy_env\python.exe" -s ComfyUI\main.py --normalvram --fast fp16_accumulation --cache-lru 6 --windows-standalone-build --listen --enable-cors-header --port 8085
::  --use-flash-attention

:: === Пауза, чтобы окно не закрылось при ошибке ===
pause