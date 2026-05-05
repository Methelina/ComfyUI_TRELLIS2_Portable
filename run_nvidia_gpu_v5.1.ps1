# ==========================================
# TRELLIS2 Portable Launcher (PS 5.1 Parser-Safe v2)
# ==========================================
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ProgressPreference = 'SilentlyContinue'

$ScriptPath = $PSScriptRoot
if (-not $ScriptPath) { $ScriptPath = '.' }
Set-Location $ScriptPath

# Safe tags to avoid parser corruption with brackets
$T_INFO = '[INFO]'
$T_WARN = '[WARN]'
$T_ERR  = '[ERROR]'

Write-Host '=========================================================='
Write-Host ' TRELLIS2 Portable Launcher'
Write-Host '=========================================================='

# ==========================================
# Pixi PATH Setup
# ==========================================
$PixiDir = Join-Path $ScriptPath 'Bin'
$PixiExe = Join-Path $PixiDir 'pixi.exe'
if (Test-Path $PixiExe) {
    $env:Path = $PixiDir + ';' + $env:Path
    Write-Host ($T_INFO + ' Pixi found in Bin and added to PATH.') -ForegroundColor Green
} else {
    Write-Host ($T_WARN + ' Pixi not found in Bin. Isolated envs may fail.') -ForegroundColor Yellow
}

# ==========================================
# PORTABILITY ISOLATION BLOCK
# ==========================================
$env:SCRIPT_DIR        = $ScriptPath
$env:PIXI_HOME         = Join-Path $ScriptPath '.pixi_home'
$env:PIXI_ENV_DIR      = Join-Path $ScriptPath '.pixi_envs'
$env:PIXI_CACHE_DIR    = Join-Path $ScriptPath '.cache\pixi'
$env:RATTLER_CACHE_DIR = Join-Path $ScriptPath '.cache\rattler'
$env:UV_CACHE_DIR      = Join-Path $ScriptPath '.cache\uv'
$env:HF_HOME           = Join-Path $ScriptPath '.cache\huggingface'
$env:HF_HUB_DOWNLOAD_TIMEOUT = '60'
$env:PIXI_NO_VERSION_CHECK   = '1'
$env:TMP               = Join-Path $ScriptPath '.cache\tmp'
$env:TEMP              = Join-Path $ScriptPath '.cache\tmp'
$env:COMFY_CE_BUILD_BASE   = Join-Path $ScriptPath '.cache\ce'
$env:BUILD_DIR         = Join-Path $ScriptPath '.cache\build_dir'

# Create dirs safely
@($env:TMP, $env:COMFY_CE_BUILD_BASE, $env:BUILD_DIR) | ForEach-Object {
    if (-not (Test-Path $_)) { New-Item -ItemType Directory -Force -Path $_ | Out-Null }
}

$env:COMFY_CACHE_DIR = Join-Path $ScriptPath '.cache\ComfyUI_Cache'
if (-not (Test-Path $env:COMFY_CACHE_DIR)) { New-Item -ItemType Directory -Force -Path $env:COMFY_CACHE_DIR | Out-Null }

# ==========================================
# Settings & Env Vars
# ==========================================
$env:HF_ENDPOINT                  = 'https://hf-mirror.com'
$env:HF_HUB_ENABLE_HF_TRANSFER    = '1'
$env:NUMEXPR_MAX_THREADS          = '32'
$env:OMP_NUM_THREADS              = '32'
$env:MKL_NUM_THREADS              = '32'
$env:MKL_DYNAMIC                  = 'TRUE'
$env:SAFETENSORS_FAST_GPU         = '1'
$env:CUDA_MODULE_LOADING          = 'LAZY'
$env:TF_ENABLE_ONEDNN_OPTS        = '1'
$env:PYTORCH_CUDA_ALLOC_CONF      = 'garbage_collection_threshold:0.8,expandable_segments:True,max_split_size_mb:128'
$env:CUDA_VISIBLE_DEVICES         = '0'
$env:COMFYUI_PORT                 = '8085'
$env:XFORMERS_MORE_DETAILS        = '1'
$env:FLASH_ATTENTION_FORCE_OPTIM  = '1'

# ==========================================
# Launch Logic
# ==========================================
$ActivateScript = Join-Path $ScriptPath 'comfy_env\Scripts\Activate.ps1'
$PythonExe      = Join-Path $ScriptPath 'comfy_env\Scripts\python.exe'
$ComfyMain      = Join-Path $ScriptPath 'ComfyUI\main.py'

if (-not (Test-Path $PythonExe)) {
    Write-Host ($T_ERR + ' python.exe not found: ' + $PythonExe) -ForegroundColor Red
    Read-Host 'Press Enter to exit'
    exit 1
}
if (-not (Test-Path $ComfyMain)) {
    Write-Host ($T_ERR + ' main.py not found: ' + $ComfyMain) -ForegroundColor Red
    Read-Host 'Press Enter to exit'
    exit 1
}

Write-Host ($T_INFO + ' Starting ComfyUI on port ' + $env:COMFYUI_PORT + ' ...') -ForegroundColor Green

if (Test-Path $ActivateScript) {
    & $ActivateScript
} else {
    Write-Host ($T_WARN + ' Activate.ps1 not found, using direct python path.') -ForegroundColor Yellow
}

# Launch command
$LaunchArgs = @(
    '-s',
    '-W', 'ignore::FutureWarning',
    $ComfyMain,
    '--normalvram',
    '--cache-lru', '6',
    '--windows-standalone-build',
    '--listen',
    '--temp-directory', $env:COMFY_CACHE_DIR,
    '--enable-cors-header',
    '--port', $env:COMFYUI_PORT
)

& $PythonExe @LaunchArgs

Write-Host ''
Read-Host 'Press Enter to exit'