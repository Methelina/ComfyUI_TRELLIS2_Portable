# ==========================================================
# TRELLIS2 Portable Launcher (PowerShell Version)
# ==========================================================
# Version: 1.2.0
# Author:  Soror L.'.L.'.
# Updated: 2026-04-27
#
# Patchnote v1.2.0 (By Soror L.'.L.'.):
#   [+] FULL ISOLATION: all runtime data inside project folder
#       - PIXI_HOME, PIXI_ENV_DIR, PIXI_CACHE_DIR
#       - RATTLER_CACHE_DIR, UV_CACHE_DIR, HF_HOME
#       - COMFY_CACHE_DIR (--temp-directory)
#   [+] Added PIXI_NO_VERSION_CHECK to prevent auto-updates
#   [*] Ensured no writes to C:\Users\... or %LOCALAPPDATA%
#   [*] Now fully portable – can be moved to any drive/folder
#
# Patchnote v1.1.0 (By Soror L.'.L.'.):
#   [+] Added Pixi support for isolated environments (comfy-env)
#   [+] Added automatic PATH update for .\Bin\pixi.exe
#   [+] Added [INFO]/[WARN] messages for Pixi availability
#   [*] Preserved all original environment variables and startup logic
#
# Patchnote v1.0.0 (By Soror L.'.L.'.):
#   [+] Initial release
# ==========================================================

# Set UTF-8 encoding and working directory
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "TRELLIS2 Portable Launcher by L.'.L.'."
Set-Location $PSScriptRoot

# ==========================================================
# ASCII Art
# ==========================================================
Write-Host " ======================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "   ██▓        ██▓    ██▓        ██▓" -ForegroundColor Cyan
Write-Host "  ▓██▒              ▓██" -ForegroundColor Cyan
Write-Host "  ██░              ▒██░" -ForegroundColor Cyan
Write-Host "  ▒██░              ▒██░" -ForegroundColor Cyan
Write-Host "  ░██████▒ ██▓  ██▓ ░██████▒ ██▓  ██▓" -ForegroundColor Cyan
Write-Host "  ░ ▒░  ░ ▒▓▒  ▒▓▒ ░ ▒░▓  ░ ▒▓▒  ▒▒" -ForegroundColor Cyan
Write-Host "  ░ ░ ▒  ░ ░▒   ░▒  ░ ░ ▒  ░ ░   ░▒" -ForegroundColor Cyan
Write-Host "    ░ ░    ░    ░     ░ ░    ░    ░" -ForegroundColor Cyan
Write-Host "      ░  ░  ░    ░      ░  ░  ░    ░" -ForegroundColor Cyan
Write-Host ""
Write-Host " ======================================================" -ForegroundColor Cyan
Write-Host "   TRELLIS2 Portable ComfyUI Launcher by Soror L.'.L.'." -ForegroundColor White
Write-Host ""

# ==========================================================
# Pixi PATH Setup
# ==========================================================
if (Test-Path ".\Bin\pixi.exe") {
    $env:PATH = ".\Bin;$env:PATH"
    Write-Host "[INFO] Pixi found in Bin and added to PATH." -ForegroundColor Green
} else {
    Write-Host "[WARN] Pixi not found in Bin. Isolated environments (comfy-env) may fail." -ForegroundColor Yellow
    Write-Host "[INFO] Please ensure pixi.exe is placed in the `"Bin`" folder next to this launcher." -ForegroundColor Yellow
}

# ==========================================================
# PORTABILITY ISOLATION BLOCK - Environment Variables
# ==========================================================
$env:SCRIPT_DIR = $PSScriptRoot
$env:PIXI_HOME = "$PSScriptRoot\.pixi_home"
$env:PIXI_ENV_DIR = "$PSScriptRoot\.pixi_envs"
$env:PIXI_CACHE_DIR = "$PSScriptRoot\.cache\pixi"
$env:RATTLER_CACHE_DIR = "$PSScriptRoot\.cache\rattler"
$env:UV_CACHE_DIR = "$PSScriptRoot\.cache\uv"
$env:HF_HOME = "$PSScriptRoot\.cache\huggingface"
$env:HF_HUB_DOWNLOAD_TIMEOUT = "60"
$env:PIXI_NO_VERSION_CHECK = "1"
$env:TMP = "$PSScriptRoot\.cache\tmp"
$env:TEMP = "$PSScriptRoot\.cache\tmp"
$env:COMFY_CE_BUILD_BASE = "$PSScriptRoot\.cache\ce"
$env:BUILD_DIR = "$PSScriptRoot\.cache\build_dir"

# Create required directories
if (-not (Test-Path $env:TMP)) { New-Item -ItemType Directory -Path $env:TMP -Force | Out-Null }
if (-not (Test-Path $env:COMFY_CE_BUILD_BASE)) { New-Item -ItemType Directory -Path $env:COMFY_CE_BUILD_BASE -Force | Out-Null }
if (-not (Test-Path $env:BUILD_DIR)) { New-Item -ItemType Directory -Path $env:BUILD_DIR -Force | Out-Null }

# ==========================================================
$env:COMFY_CACHE_DIR = "$PSScriptRoot\.cache\ComfyUI_Cache"
if (-not (Test-Path $env:COMFY_CACHE_DIR)) { New-Item -ItemType Directory -Path $env:COMFY_CACHE_DIR -Force | Out-Null }

# ==========================================================
# Proxy settings (uncomment if needed)
# ==========================================================
# $env:HTTP_PROXY = "http://127.0.0.1:18080"
# $env:HTTPS_PROXY = "http://127.0.0.1:18080"
# $env:NO_PROXY = "localhost,127.0.0.1,::1"

# ==========================================================
# Hugging Face settings
# ==========================================================
# $env:HF_ENDPOINT = "https://hf-mirror.com"
$env:HF_HUB_DOWNLOAD_TIMEOUT = "60"
# $env:HF_HUB_ENABLE_HF_TRANSFER = "1"

# ==========================================================
# CPU and threads configuration
# ==========================================================
$env:NUMEXPR_MAX_THREADS = "32"
$env:OMP_NUM_THREADS = "32"
$env:MKL_NUM_THREADS = "32"
$env:MKL_DYNAMIC = "TRUE"
$env:MKL_NUMA_DOMAIN = "ALL"

# ==========================================================
# Acceleration and GPU settings
# ==========================================================
$env:SAFETENSORS_FAST_GPU = "1"
$env:CUDA_MODULE_LOADING = "LAZY"
$env:TF_ENABLE_ONEDNN_OPTS = "1"
$env:NVIDIA_TF32_OVERRIDE = "1"
$env:TORCH_ALLOW_TF32_CUBLAS_OVERRIDE = "1"
$env:TORCH_CUDNN_V8_API_ENABLED = "1"

# ==========================================================
# PyTorch memory configuration (tuned for 12 GB VRAM TITAN V)
# ==========================================================
$env:PYTORCH_CUDA_ALLOC_CONF = "garbage_collection_threshold:0.8,expandable_segments:True,max_split_size_mb:128"

# ==========================================================
# GPU settings
# ==========================================================
$env:CUDA_VISIBLE_DEVICES = "0"

# ==========================================================
# ComfyUI port
# ==========================================================
$env:COMFYUI_PORT = "8085"

# ==========================================================
# Attention settings
# ==========================================================
$env:XFORMERS_MORE_DETAILS = "1"
$env:FLASH_ATTENTION_FORCE_OPTIM = "1"
# $env:NAF_USE_BF16 = "1"

# ==========================================================
# Update ComfyUI-Trellis2-GGUF (uncomment if needed)
# ==========================================================
 Write-Host "[INFO] Updating ComfyUI-Trellis2-GGUF..." -ForegroundColor Cyan
 Set-Location "$PSScriptRoot\ComfyUI\custom_nodes\ComfyUI-Trellis2-GGUF"
 if (Test-Path ".git") { git pull origin main } else { Write-Host "[WARN] ComfyUI-Trellis2-GGUF is not a Git repository — skipping update." -ForegroundColor Yellow }
 Set-Location $PSScriptRoot
 Write-Host "[INFO] ComfyUI-Trellis2-GGUF update attempt completed." -ForegroundColor Cyan
 Write-Host ""
 
# ==========================================================
# Update ComfyUI-Trellis2 (uncomment if needed)
# ==========================================================
 Write-Host "[INFO] Updating ComfyUI-Trellis2-GGUF..." -ForegroundColor Cyan
 Set-Location "$PSScriptRoot\ComfyUI\custom_nodes\ComfyUI-Trellis2"
 if (Test-Path ".git") { git pull origin main } else { Write-Host "[WARN] ComfyUI-Trellis2 is not a Git repository — skipping update." -ForegroundColor Yellow }
 Set-Location $PSScriptRoot
 Write-Host "[INFO] ComfyUI-Trellis2 update attempt completed." -ForegroundColor Cyan
 Write-Host "" 

# ==========================================================
# Environment activation and ComfyUI launch (SINGLE LINE)
# ==========================================================
& "$PSScriptRoot\comfy_env\Scripts\Activate.ps1"; python -s -W ignore::FutureWarning "$PSScriptRoot\ComfyUI\main.py" --lowvram --cache-lru 6 --windows-standalone-build  --enable-dynamic-vram --listen --temp-directory $env:COMFY_CACHE_DIR --enable-cors-header --port $env:COMFYUI_PORT

# Optional flags (uncomment if needed):
# --use-flash-attention
# --fast fp16_accumulation

# ==========================================================
# Pause
# ==========================================================
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")