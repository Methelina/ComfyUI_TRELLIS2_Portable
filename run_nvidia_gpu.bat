@echo off
chcp 65001 >nul
title TRELLIS2 Portable Launcher by L.'.L.'.
cd /d "%~dp0"

echo  ======================================================
echo.
echo    ██▓        ██▓    ██▓        ██▓
echo   ▓██▒              ▓██
echo   ██░              ▒██░
echo   ▒██░              ▒██░
echo   ░██████▒ ██▓  ██▓ ░██████▒ ██▓  ██▓
echo   ░ ▒░  ░ ▒▓▒  ▒▓▒ ░ ▒░▓  ░ ▒▓▒  ▒▒
echo   ░ ░ ▒  ░ ░▒   ░▒  ░ ░ ▒  ░ ░   ░▒
echo     ░ ░    ░    ░     ░ ░    ░    ░
echo       ░  ░  ░    ░      ░  ░  ░    ░
echo.
echo  ======================================================
echo    TRELLIS2 Portable ComfyUI Launcher by Soror L.'.L.'.
echo.

if exist ".\Bin\pixi.exe" (
    set "PATH=.\Bin;%PATH%"
    echo [INFO] Pixi found in Bin and added to PATH.
) else (
    echo [WARN] Pixi not found in Bin. Isolated environments (comfy-env) may fail.
    echo [INFO] Please ensure pixi.exe is placed in the "Bin" folder next to this launcher.
)

set "SCRIPT_DIR=%~dp0"
set "PIXI_HOME=%~dp0.pixi_home"
set "PIXI_ENV_DIR=%~dp0.pixi_envs"
set "PIXI_CACHE_DIR=%~dp0.cache\pixi"
set "RATTLER_CACHE_DIR=%~dp0.cache\rattler"
set "UV_CACHE_DIR=%~dp0.cache\uv"
set "HF_HOME=%~dp0.cache\huggingface"
set "HF_HUB_DOWNLOAD_TIMEOUT=60"
set "PIXI_NO_VERSION_CHECK=1"
set "TMP=%~dp0.cache\tmp"
set "TEMP=%~dp0.cache\tmp"
set "COMFY_CE_BUILD_BASE=%~dp0.cache\ce"
set "BUILD_DIR=%~dp0.cache\build_dir"

if not exist "%TMP%" mkdir "%TMP%"
if not exist "%COMFY_CE_BUILD_BASE%" mkdir "%COMFY_CE_BUILD_BASE%"
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

set "COMFY_CACHE_DIR=%~dp0.cache\ComfyUI_Cache"
if not exist "%COMFY_CACHE_DIR%" mkdir "%COMFY_CACHE_DIR%"

set "NUMEXPR_MAX_THREADS=32"
set "OMP_NUM_THREADS=32"
set "MKL_NUM_THREADS=32"
set "MKL_DYNAMIC=TRUE"
set "MKL_NUMA_DOMAIN=ALL"

set "SAFETENSORS_FAST_GPU=1"
set "CUDA_MODULE_LOADING=LAZY"
set "TF_ENABLE_ONEDNN_OPTS=1"
set "NVIDIA_TF32_OVERRIDE=1"
set "TORCH_ALLOW_TF32_CUBLAS_OVERRIDE=1"
set "TORCH_CUDNN_V8_API_ENABLED=1"

set "PYTORCH_CUDA_ALLOC_CONF=garbage_collection_threshold:0.8,expandable_segments:True,max_split_size_mb:128"

set "CUDA_VISIBLE_DEVICES=0"

set "COMFYUI_PORT=8085"

set "XFORMERS_MORE_DETAILS=1"
set "FLASH_ATTENTION_FORCE_OPTIM=1"

echo [INFO] Updating ComfyUI-Trellis2-GGUF...

cd /d "%~dp0ComfyUI\custom_nodes\ComfyUI-Trellis2-GGUF"
if exist ".git" (git pull origin main) else (echo [WARN] ComfyUI-Trellis2-GGUF is not a Git repository - skipping update.)
cd /d "%~dp0"
echo [INFO] ComfyUI-Trellis2-GGUF update attempt completed.
echo.

echo [INFO] Updating ComfyUI-Trellis2...

cd /d "%~dp0ComfyUI\custom_nodes\ComfyUI-Trellis2"
if exist ".git" (git pull origin main) else (echo [WARN] ComfyUI-Trellis2 is not a Git repository - skipping update.)
cd /d "%~dp0"
echo [INFO] ComfyUI-Trellis2 update attempt completed.
echo.

call "%~dp0comfy_env\Scripts\activate.bat"
python -s -W ignore::FutureWarning "%~dp0ComfyUI\main.py" --lowvram --cache-lru 6 --preview-method taesd --windows-standalone-build --enable-dynamic-vram --listen --temp-directory "%COMFY_CACHE_DIR%" --enable-cors-header --port %COMFYUI_PORT%

echo.
echo Press any key to exit...
pause >nul
