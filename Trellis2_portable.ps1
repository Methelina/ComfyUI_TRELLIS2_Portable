<#
.SYNOPSIS
    ComfyUI Installer v0.3.1 (PyTorch via Index, English UI)
    Stage numbering and localized to English.
    
    Version: 0.3.1
    Author: Soror L.'.L.'. (Modified by pytraveler)
#>

# ==========================================
# === Path & Init ===
 $ScriptPath = $PSScriptRoot
if (-not $ScriptPath) { $ScriptPath = "." }
Set-Location $ScriptPath
 $SettingsFile = "settings.yaml"
 $WheelsDir = "wheels"

# Load Config
if (-not (Test-Path $SettingsFile)) {
    Write-Host "ERROR: File $SettingsFile not found!" -ForegroundColor Red
    exit 1
}

 $yamlText = Get-Content $SettingsFile -Raw

# 1. Extract Settings
 $config = @{}
 $config['env_name'] = if ($yamlText -match "env_name:\s*`"(.+?)`"") { $matches[1] } else { "comfy_env" }
 $config['python_version'] = if ($yamlText -match "python_version:\s*`"(.+?)`"") { $matches[1] } else { "3.12" }
 $config['comfy_dir'] = if ($yamlText -match "comfy_dir:\s*`"(.+?)`"") { $matches[1] } else { "ComfyUI" }

# 2. Extract Nodes
 $nodeList = @()
if ($yamlText -match "nodes:([\s\S]*?)(?=wheels:|pypi_packages:|\Z)") {
    $nodeBlock = $matches[1]
    $matches = [regex]::Matches($nodeBlock, "- url:\s*`"([^`"]+)`"\s+name:\s*`"([^`"]+)`"")
    foreach ($m in $matches) {
        $nodeList += @{ url = $m.Groups[1].Value; name = $m.Groups[2].Value }
    }
}

# 3. Extract Wheels (Only xFormers now)
 $wheelList = @{}
if ($yamlText -match "wheels:([\s\S]*?)(?=nodes:|pypi_packages:|\Z)") {
    $wheelBlock = $matches[1]
    $entries = $wheelBlock -split "  [a-z_]+:", [System.StringSplitOptions]::RemoveEmptyEntries | Where-Object { $_ -match "url:" }
    foreach ($entry in $entries) {
        if ($entry -match "^\s*([a-z_]+):\s*\n\s+url:\s*`"([^`"]+)`"\s+no_deps:\s*(true|false)") {
            $name = $matches[1]
            $url = $matches[2]
            $noDeps = $matches[3] -eq "true"
            $wheelList[$name] = @{ url = $url; no_deps = $noDeps }
        }
    }
}

# === Vars ===
 $EnvName = $config['env_name']
 $ComfyDir = $config['comfy_dir']
 $UvVersion = "0.11.6"
 $UvZipUrl = "https://releases.astral.sh/github/uv/releases/download/$UvVersion/uv-x86_64-pc-windows-msvc.zip"
 $UvExePath = Join-Path $ScriptPath "uv.exe"
 $PythonExePath = Join-Path $ScriptPath "$EnvName\Scripts\python.exe"
 $PythonSymlinkPath = Join-Path $ScriptPath "$EnvName\python.exe"
# uv pip uses --no-cache instead of pip's --no-cache-dir
 $PIPargs = "--no-cache"

# === Functions ===
function Write-Status {
    param([string]$Message, [string]$Type = "INFO")
    $prefix = switch ($Type) {
        "INFO"   { " [INFO]  " }
        "WARN"   { " [WARN]  " }
        "ERROR"  { " [ERROR] " }
        "SUCCESS"{ " [OK]    " }
        default  { " [INFO]  " }
    }
    $color = switch ($Type) {
        "INFO"   { "Cyan" }
        "WARN"   { "Yellow" }
        "ERROR"  { "Red" }
        "SUCCESS"{ "Green" }
        default  { "White" }
    }
    Write-Host "$prefix$Message" -ForegroundColor $color
}

function Write-Step {
    param([string]$Message, [int]$Step, [int]$Total)
    Write-Host ""
    Write-Host ">>> Stage [$Step/$Total]: $Message" -ForegroundColor Magenta
}

function Test-Command {
    param([string]$Cmd)
    return $null -ne (Get-Command $Cmd -ErrorAction SilentlyContinue)
}

function Invoke-UvPipInstall {
    param([string]$Command)
    Write-Host "   > uv pip install $Command" -ForegroundColor DarkGray
    $process = Start-Process -FilePath $UvExePath -ArgumentList "pip install --python `"$PythonExePath`" $Command" -NoNewWindow -Wait -PassThru
    if ($process.ExitCode -ne 0) {
        Write-Status "Execution failed (code $($process.ExitCode))" "ERROR"
    }
    return $process.ExitCode
}

function Invoke-PythonCommand {
    param([string]$Command)
    Write-Host "   > python $Command" -ForegroundColor DarkGray
    $process = Start-Process -FilePath $PythonExePath -ArgumentList $Command -NoNewWindow -Wait -PassThru
    if ($process.ExitCode -ne 0) {
        Write-Status "Execution failed (code $($process.ExitCode))" "ERROR"
    }
    return $process.ExitCode
}

function Get-OrDownload-Wheel {
    param([string]$Name, [string]$Url)
    $fileName = [System.IO.Path]::GetFileName($Url)
    $localPath = Join-Path $ScriptPath $WheelsDir
    $filePath = Join-Path $localPath $fileName
    if (-not (Test-Path $localPath)) { New-Item -ItemType Directory -Force -Path $localPath | Out-Null }
    if (Test-Path $filePath) {
        Write-Host "   [CACHE] $Name found locally." -ForegroundColor Gray
    } else {
        Write-Host "   [DOWN]  Downloading $Name..." -ForegroundColor Yellow
        try {
            Invoke-WebRequest -Uri $Url -OutFile $filePath
            Write-Host "   [OK]    $Name downloaded." -ForegroundColor Green
        } catch {
            Write-Host "   [ERR]   Error downloading $Name : $_" -ForegroundColor Red
            return $null
        }
    }
    return $filePath
}

# === Header ===
Write-Host " ===========================================	" -ForegroundColor Green
Write-Host ""
Write-Host "  ██▓        ██▓    ██▓        ██▓				" -ForegroundColor Yellow
Write-Host " ▓██▒              ▓██▒							" -ForegroundColor Yellow
Write-Host " ▒██░              ▒██░							" -ForegroundColor Yellow
Write-Host " ▒██░              ▒██░							" -ForegroundColor Yellow
Write-Host " ░██████▒ ██▓  ██▓ ░██████▒ ██▓  ██▓			" -ForegroundColor Yellow
Write-Host " ░ ▒░▓  ░ ▒▓▒  ▒▓▒ ░ ▒░▓  ░ ▒▓▒  ▒▓▒			" -ForegroundColor Yellow
Write-Host " ░ ░ ▒  ░ ░▒   ░▒  ░ ░ ▒  ░ ░▒   ░▒				" -ForegroundColor Yellow
Write-Host "   ░ ░    ░    ░     ░ ░    ░    ░				" -ForegroundColor Yellow
Write-Host "     ░  ░  ░    ░      ░  ░  ░    ░				" -ForegroundColor Yellow
Write-Host ""
Write-Host "  ===========================================	" -ForegroundColor Green
Write-Host "    ComfyUI TRELLIS2 by Soror L.'.L.'." -ForegroundColor Yellow
Write-Host "    Portable Installer v0.1.2" -ForegroundColor Green
Write-Host "  ===========================================	" -ForegroundColor Green
Write-Host ""
# ==========================================

# === 0. Download uv ===
Write-Step "Downloading uv Package Manager ($UvVersion)..." 0 10
if (-not (Test-Path $UvExePath)) {
    $uvZip = Join-Path $ScriptPath "uv.zip"
    Write-Status "Downloading uv $UvVersion..." "INFO"
    try {
        Invoke-WebRequest -Uri $UvZipUrl -OutFile $uvZip -ErrorAction Stop
    } catch {
        Write-Status "Download failed: $($_.Exception.Message)" "ERROR"
        Remove-Item $uvZip -Force -ErrorAction SilentlyContinue
        Read-Host "Press Enter to exit"
        exit 1
    }
    if ((Test-Path $uvZip) -and (Get-Item $uvZip).Length -lt 1000) {
        Write-Status "Downloaded file is too small, likely an error page. Cleaning up..." "ERROR"
        Remove-Item $uvZip -Force -ErrorAction SilentlyContinue
        Read-Host "Press Enter to exit"
        exit 1
    }
    $uvTmp = Join-Path $ScriptPath "uv_tmp"
    if (Test-Path $uvTmp) { Remove-Item $uvTmp -Recurse -Force }
    Expand-Archive -Path $uvZip -DestinationPath $uvTmp -Force
    $extractedDir = Get-ChildItem -Path $uvTmp -Directory | Select-Object -First 1
    if (-not $extractedDir) {
        # Files are directly in uv_tmp, no subdirectory
        $extractedDir = @{ FullName = $uvTmp }
    }
    Copy-Item (Join-Path $extractedDir.FullName "uv.exe") $UvExePath
    Copy-Item (Join-Path $extractedDir.FullName "uvx.exe") (Join-Path $ScriptPath "uvx.exe") -ErrorAction SilentlyContinue
    Remove-Item $uvTmp -Recurse -Force
    Remove-Item $uvZip -Force
    Write-Status "uv $UvVersion extracted successfully." "SUCCESS"
} else {
    Write-Status "uv.exe already exists, skipping download." "SUCCESS"
}

# === 1. Check Deps ===
Write-Step "Checking Dependencies (Git)..." 1 10
 $Missing = @()
if (!(Test-Command "git")) { $Missing += "Git" }

if ($Missing.Count -gt 0) {
    Write-Status "CRITICAL ERROR: Missing dependencies." "ERROR"
    Write-Host "Not installed: $($Missing -join ', ')" -ForegroundColor Red
    Write-Host "Please install them manually and restart." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Status "Dependencies found." "SUCCESS"

# === 2. Check Folders ===
Write-Step "Checking Directory Structure..." 2 10
if (Test-Path $EnvName) {
    Write-Status "Environment folder '$EnvName' already exists." "WARN"
    $ans = Read-Host "Delete and recreate? (Y/N)"
    if ($ans -eq 'Y' -or $ans -eq 'y') {
        Remove-Item -Path $EnvName -Recurse -Force
    } else {
        Write-Status "Installation aborted." "ERROR"
        exit 1
    }
}
if (Test-Path $ComfyDir) {
    Write-Status "Folder '$ComfyDir' already exists." "WARN"
    Write-Host "Please delete folder '$ComfyDir' for a clean install." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# === 3. Create Env ===
Write-Step "Creating Python Environment with uv ($EnvName)..." 3 10
 $EnvDirPath = Join-Path $ScriptPath $EnvName
& $UvExePath venv $EnvDirPath --python $config['python_version']
if ($LASTEXITCODE -ne 0) {
    Write-Status "Failed to create environment." "ERROR"
    exit 1
}
# Create compatibility entry point: comfy_env\python.exe → comfy_env\Scripts\python.exe
# This allows all existing .bat files and Python scripts to use the old Conda-style path
$pythonTarget = Join-Path $EnvDirPath "Scripts\python.exe"
$pythonLink = Join-Path $EnvDirPath "python.exe"
if (-not (Test-Path $pythonLink)) {
    # Try hardlink first, fall back to .bat wrapper
    $hardlinkCreated = $false
    try {
        $null = New-Item -ItemType HardLink -Path $pythonLink -Target $pythonTarget -ErrorAction Stop
        Write-Status "Created hardlink: python.exe -> Scripts\python.exe" "SUCCESS"
        $hardlinkCreated = $true
    } catch {
        # Hardlink failed
    }
    if (-not $hardlinkCreated) {
        # Create .bat wrapper as fallback
        Set-Content -Path $pythonLink -Value "@`"%~dp0Scripts\python.exe`" %*" -Encoding ASCII
        Write-Status "Created .bat wrapper: python.exe -> Scripts\python.exe (hardlink unavailable)" "WARN"
    }
}
Write-Status "Environment created." "SUCCESS"

# === 4. Install PyTorch (Via Index) ===
Write-Step "Installing PyTorch (Torch 2.8 + Torch 0.23 + Audio 2.8)..." 4 10
 $TorchCmd = "torch==2.8.0+cu128 torchvision==0.23.0+cu128 torchaudio==2.8.0+cu128 --extra-index-url https://download.pytorch.org/whl/cu128"
Invoke-UvPipInstall $TorchCmd

# === 5. Install Wheels (xFormers) ===
Write-Step "Installing Specific Wheels (xFormers)..." 5 10
foreach ($key in $wheelList.Keys) {
    $info = $wheelList[$key]
    $localWheelPath = Get-OrDownload-Wheel -Name $key -Url $info.url
    if ($localWheelPath) {
        $depsFlag = if ($info.no_deps) { "--no-deps" } else { "" }
        Invoke-UvPipInstall "`"$localWheelPath`" $depsFlag $PIPargs"
    } else {
        Write-Status "Skipping $key due to download error." "WARN"
    }
}

# Install base pip packages
Invoke-UvPipInstall "pygit2 $PIPargs"

# === 6. Install PyPI Packages ===
Write-Step "Installing PyPI Packages..." 6 10
if ($yamlText -match "pypi_packages:([\s\S]*?)(?=\Z|wheels:|nodes:)") {
    $pypiBlock = $matches[1]
    # Simple packages
    $simpleMatches = [regex]::Matches($pypiBlock, "- name:\s*`"([a-zA-Z0-9_-]+)`"(?!.*url:)")
    foreach ($m in $simpleMatches) {
        Invoke-UvPipInstall "$($m.Groups[1].Value) $PIPargs"
    }
    # URL packages
    $urlMatches = [regex]::Matches($pypiBlock, "- name:\s*`"([a-zA-Z0-9_-]+)`"\s+url:\s*`"([^`"]+)`"")
    foreach ($m in $urlMatches) {
        $name = $m.Groups[1].Value
        $url = $m.Groups[2].Value
        $localPath = Get-OrDownload-Wheel -Name $name -Url $url
        if ($localPath) { Invoke-UvPipInstall "`"$localPath`" $PIPargs" }
    }
}

# === 7. Clone & ComfyUI ===
Write-Step "Cloning ComfyUI and Installing Requirements..." 7 10
git clone https://github.com/comfyanonymous/ComfyUI $ComfyDir
Set-Location $ComfyDir
Invoke-UvPipInstall "-r `"requirements.txt`" $PIPargs"
Set-Location $ScriptPath

Write-Status "Installing Custom Nodes..." "INFO"
foreach ($node in $nodeList) {
    Write-Host "   > Cloning: $($node.name)" -ForegroundColor Cyan
    git clone $node.url "$ComfyDir\custom_nodes\$($node.name)" 2>$null | Out-Null

    $reqPath = "$ComfyDir\custom_nodes\$($node.name)\requirements.txt"
    if (Test-Path $reqPath) {
        Invoke-UvPipInstall "-r `"$reqPath`" $PIPargs"
    }

    $installPath = "$ComfyDir\custom_nodes\$($node.name)\install.py"
    if (Test-Path $installPath) {
        Invoke-PythonCommand "`"$installPath`""
    }
}

# === 8. Helper Files ===
Write-Step "Processing Helper Files..." 8 10

# --- Обработка Supp.tar.gz ---
if (Test-Path "Supp.tar.gz") {
    Write-Status "Extracting Supp.tar.gz to ComfyUI directory..." "INFO"
    
    # Создаём временную папку для распаковки
    $tempExtractDir = Join-Path $env:TEMP "Supp_extract_$(Get-Random)"
    New-Item -ItemType Directory -Force -Path $tempExtractDir | Out-Null
    
    # Распаковываем архив во временную папку
    tar.exe -xzf "Supp.tar.gz" -C $tempExtractDir
    
    # Копируем содержимое Supp/ComfyUI/ в целевую папку ComfyUI с заменой
    $sourceSupp = Join-Path $tempExtractDir "Supp\ComfyUI"
    if (Test-Path $sourceSupp) {
        Copy-Item -Path "$sourceSupp\*" -Destination $ComfyDir -Recurse -Force
        Write-Status "Helper files merged into $ComfyDir" "SUCCESS"
    } else {
        Write-Status "Warning: Expected structure Supp/ComfyUI not found in archive" "WARN"
    }
    
    # Очищаем временную папку
    Remove-Item -Path $tempExtractDir -Recurse -Force
}

# --- Обработка xformers-0.0.33.tar.gz ---
 $xformersFile = "update\xformers-0.0.33.tar.gz"
 $sitePackagesPath = "comfy_env\Lib\site-packages"

if (Test-Path $xformersFile) {
    Write-Status "Extracting xformers-0.0.33.tar.gz to Python environment..." "INFO"
    
    # Проверяем существование папки site-packages
    if (-not (Test-Path $sitePackagesPath)) {
        New-Item -ItemType Directory -Force -Path $sitePackagesPath | Out-Null
    }
    
    tar.exe -xzf $xformersFile -C $sitePackagesPath
    
    Write-Status "xformers installed to $sitePackagesPath" "SUCCESS"
} else {
    Write-Status "xformers-0.0.33.tar.gz not found in update/, skipping..." "WARN"
}

# --- Обработка flash_attn-2.8.2.tar.gz ---
 $flashAttnFile = "update\flash_attn-2.8.2.tar.gz"

if (Test-Path $flashAttnFile) {
    Write-Status "Extracting flash_attn-2.8.2.tar.gz to Python environment..." "INFO"
    
    # Проверяем существование папки site-packages
    if (-not (Test-Path $sitePackagesPath)) {
        New-Item -ItemType Directory -Force -Path $sitePackagesPath | Out-Null
    }
    
    tar.exe -xzf $flashAttnFile -C $sitePackagesPath
    
    Write-Status "flash_attn installed to $sitePackagesPath" "SUCCESS"
} else {
    Write-Status "flash_attn-2.8.2.tar.gz not found in update/, skipping..." "WARN"
}

# === 9. Install Trellis2 GGUF ===
Write-Step "Installing Trellis2 GGUF (Models and Wheels)..." 9 10

$TrellisScript = "Update\trellis2setup.py"
if (Test-Path $TrellisScript) {
    Write-Status "Running Trellis2 setup script..." "INFO"
    Invoke-PythonCommand "`"$TrellisScript`""
} else {
    Write-Status "Trellis2 setup script not found at $TrellisScript" "WARN"
}

# === Finish ===
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                INSTALLATION COMPLETE                         ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host ""
Read-Host "Press Enter to exit"