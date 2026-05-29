# ==========================================================
# TRELLIS2 Portable Launcher (PowerShell Version)
# MultiGPU Edition - ComfyUI-MultiGPU v2 Support
# ==========================================================
# Version: 1.3.3
# Author:  Soror L.'.L.'.
# Updated: 2026-05-19
#
# Patchnote v1.3.3:
#   [+] Tuned for ComfyUI-MultiGPU v2 (pollockjj fork)
#   [+] Added --force-fp16 --fp16-unet --fp16-vae --fp16-text-enc for Volta CC7.0
#   [+] Added --disable-cuda-malloc --disable-async-offload --disable-dynamic-vram
#   [+] Added --reserve-vram 512 for WDDM stability on 12GB cards
#   [+] Switched to --normalvram (12GB is not high for modern models)
#   [+] Single-line arguments per user request
#   [*] All comments in ASCII-only
#
# Patchnote v1.3.0:
#   [+] CUDA_VISIBLE_DEVICES = "0,1" - both GPUs visible to PyTorch
#   [+] Removed --cuda-device for MultiGPU node compatibility
#   [+] Tuned PYTORCH_CUDA_ALLOC_CONF for dual-GPU setups
# ==========================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "TRELLIS2 MultiGPU Launcher by L.'.L.'."
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
Write-Host "   Mode: ComfyUI-MultiGPU v2 - both GPUs visible" -ForegroundColor Yellow
Write-Host ""

# ==========================================================
# Pixi PATH Setup
# ==========================================================
if (Test-Path ".\Bin\pixi.exe") {
    $env:PATH = ".\Bin;$env:PATH"
    Write-Host "[INFO] Pixi found in Bin and added to PATH." -ForegroundColor Green
} else {
    Write-Host "[WARN] Pixi not found in Bin. Isolated environments may fail." -ForegroundColor Yellow
}

# ==========================================================
# PORTABILITY ISOLATION BLOCK - Environment Variables
# ==========================================================
$env:SCRIPT_DIR      = $PSScriptRoot
$env:PIXI_HOME       = "$PSScriptRoot\.pixi_home"
$env:PIXI_ENV_DIR    = "$PSScriptRoot\.pixi_envs"
$env:PIXI_CACHE_DIR  = "$PSScriptRoot\.cache\pixi"
$env:RATTLER_CACHE_DIR = "$PSScriptRoot\.cache\rattler"
$env:UV_CACHE_DIR    = "$PSScriptRoot\.cache\uv"
$env:HF_HOME         = "$PSScriptRoot\.cache\huggingface"
$env:PIXI_NO_VERSION_CHECK = "1"
$env:TMP             = "$PSScriptRoot\.cache\tmp"
$env:TEMP            = "$PSScriptRoot\.cache\tmp"
$env:COMFY_CE_BUILD_BASE = "$PSScriptRoot\.cache\ce"
$env:BUILD_DIR       = "$PSScriptRoot\.cache\build_dir"

if (-not (Test-Path $env:TMP)) { New-Item -ItemType Directory -Path $env:TMP -Force | Out-Null }
if (-not (Test-Path $env:COMFY_CE_BUILD_BASE)) { New-Item -ItemType Directory -Path $env:COMFY_CE_BUILD_BASE -Force | Out-Null }
if (-not (Test-Path $env:BUILD_DIR)) { New-Item -ItemType Directory -Path $env:BUILD_DIR -Force | Out-Null }

$env:COMFY_CACHE_DIR = "$PSScriptRoot\.cache\ComfyUI_Cache"
if (-not (Test-Path $env:COMFY_CACHE_DIR)) { New-Item -ItemType Directory -Path $env:COMFY_CACHE_DIR -Force | Out-Null }

# ==========================================================
# Hugging Face settings
# ==========================================================
$env:HF_HUB_DOWNLOAD_TIMEOUT = "60"

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

# ==========================================================
# MULTI-GPU CORE CONFIGURATION
# ==========================================================
$env:CUDA_VISIBLE_DEVICES = "0,1"

$env:NCCL_DEBUG = "WARN"
$env:NCCL_IB_DISABLE = "1"
$env:NCCL_P2P_DISABLE = "0"

# ==========================================================
# PyTorch memory configuration - TUNED FOR 2 GPUs
# ==========================================================
$env:PYTORCH_CUDA_ALLOC_CONF = "garbage_collection_threshold:0.6,expandable_segments:True,max_split_size_mb:512"

# ==========================================================
# ComfyUI port
# ==========================================================
$env:COMFYUI_PORT = "8085"

# ==========================================================
# Attention settings
# ==========================================================
$env:XFORMERS_MORE_DETAILS = "1"
$env:FLASH_ATTENTION_FORCE_OPTIM = "1"

# ==========================================================
# MultiGPU-specific: stabilization
# ==========================================================
$env:CUDA_LAUNCH_BLOCKING = "0"
$env:CUDA_DEVICE_ORDER = "PCI_BUS_ID"

# ==========================================================
# GUARD: verify critical env vars are not empty
# ==========================================================
if ([string]::IsNullOrWhiteSpace($env:COMFY_CACHE_DIR)) {
    Write-Host "[FATAL] COMFY_CACHE_DIR is empty. Aborting." -ForegroundColor Red
    exit 1
}
if ([string]::IsNullOrWhiteSpace($env:COMFYUI_PORT)) {
    Write-Host "[FATAL] COMFYUI_PORT is empty. Aborting." -ForegroundColor Red
    exit 1
}

# ==========================================================
# Optional: warn if ComfyUI-MultiGPU not installed
# ==========================================================
$multiGpuPath = "$PSScriptRoot\ComfyUI\custom_nodes\ComfyUI-MultiGPU"
if (-not (Test-Path $multiGpuPath)) {
    Write-Host "[WARN] ComfyUI-MultiGPU not found." -ForegroundColor Yellow
    Write-Host "[INFO] Install via Manager or: git clone https://github.com/pollockjj/ComfyUI-MultiGPU.git" -ForegroundColor Cyan
}

# ==========================================================
# Environment activation and ComfyUI launch
# ==========================================================
Write-Host "[INFO] Launching ComfyUI with both GPUs visible..." -ForegroundColor Green
Write-Host "[INFO] Use MultiGPU/DisTorch2 nodes in workflow to distribute model components" -ForegroundColor Green
Write-Host ""

& "$PSScriptRoot\comfy_env\Scripts\Activate.ps1"

$pythonExe = "$PSScriptRoot\comfy_env\Scripts\python.exe"
$mainPy    = "$PSScriptRoot\ComfyUI\main.py"

& $pythonExe -s -W ignore::FutureWarning $mainPy --normalvram --force-fp16 --fp16-unet --fp16-vae --fp16-text-enc --disable-cuda-malloc --disable-async-offload --disable-dynamic-vram --reserve-vram 512 --cache-lru 12 --windows-standalone-build --listen --temp-directory "$env:COMFY_CACHE_DIR" --enable-cors-header --port $env:COMFYUI_PORT

# ==========================================================
# Pause
# ==========================================================
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")