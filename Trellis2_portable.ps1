<#
.SYNOPSIS
    ComfyUI Installer v0.3.0 (PyTorch via Index, English UI)
    Stage numbering and localized to English.
    
    Version: 0.3.0
    Author: Soror L.'.L.'. (Modified by AI Assistant)
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
 $CondaPath = (Get-Command conda).Source
 $PIPargs = "--no-cache-dir --no-warn-script-location --timeout=1000 --retries 200"

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

function Invoke-CondaCommand {
    param([string]$Command)
    Write-Host "   > $Command" -ForegroundColor DarkGray
    $fullEnvPath = Join-Path $ScriptPath $EnvName
    $process = Start-Process -FilePath $CondaPath -ArgumentList "run -p `"$fullEnvPath`" $Command" -NoNewWindow -Wait -PassThru
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
Write-Host "    Portable Installer v0.1.1" -ForegroundColor Green
Write-Host "  ===========================================	" -ForegroundColor Green
Write-Host ""
# ==========================================

# === 1. Check Deps ===
Write-Step "Checking Dependencies (Git, Conda)..." 1 9
 $Missing = @()
if (!(Test-Command "git")) { $Missing += "Git" }
if (!(Test-Command "conda")) { $Missing += "Conda" }

if ($Missing.Count -gt 0) {
    Write-Status "CRITICAL ERROR: Missing dependencies." "ERROR"
    Write-Host "Not installed: $($Missing -join ', ')" -ForegroundColor Red
    Write-Host "Please install them manually and restart." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Status "Dependencies found." "SUCCESS"

# === 2. Check Folders ===
Write-Step "Checking Directory Structure..." 2 9
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
Write-Step "Creating Conda Environment ($EnvName)..." 3 9
 $EnvDirPath = Join-Path $ScriptPath $EnvName
& $CondaPath create -p $EnvDirPath python=$($config['python_version']) -y -q
if ($LASTEXITCODE -ne 0) {
    Write-Status "Failed to create environment." "ERROR"
    exit 1
}
Write-Status "Environment created." "SUCCESS"

# === 4. Install PyTorch (Via Index) ===
Write-Step "Installing PyTorch (Torch 2.8 + Torch 0.23 + Audio 2.8)..." 4 9
# Using the command provided by the user
 $TorchCmd = "pip install torch==2.8.0+cu128 torchvision==0.23.0+cu128 torchaudio==2.8.0+cu128 --extra-index-url https://download.pytorch.org/whl/cu128"
Invoke-CondaCommand $TorchCmd

# === 5. Install Wheels (xFormers) ===
Write-Step "Installing Specific Wheels (xFormers)..." 5 9
foreach ($key in $wheelList.Keys) {
    $info = $wheelList[$key]
    $localWheelPath = Get-OrDownload-Wheel -Name $key -Url $info.url
    if ($localWheelPath) {
        $depsFlag = if ($info.no_deps) { "--no-deps" } else { "" }
        Invoke-CondaCommand "pip install `"$localWheelPath`" $depsFlag $PIPargs"
    } else {
        Write-Status "Skipping $key due to download error." "WARN"
    }
}

# Install base pip packages
Invoke-CondaCommand "pip install pygit2 $PIPargs"

# === 6. Install PyPI Packages ===
Write-Step "Installing PyPI Packages..." 6 9
if ($yamlText -match "pypi_packages:([\s\S]*?)(?=\Z|wheels:|nodes:)") {
    $pypiBlock = $matches[1]
    # Simple packages
    $simpleMatches = [regex]::Matches($pypiBlock, "- name:\s*`"([a-zA-Z0-9_-]+)`"(?!.*url:)")
    foreach ($m in $simpleMatches) {
        Invoke-CondaCommand "pip install $($m.Groups[1].Value) $PIPargs"
    }
    # URL packages
    $urlMatches = [regex]::Matches($pypiBlock, "- name:\s*`"([a-zA-Z0-9_-]+)`"\s+url:\s*`"([^`"]+)`"")
    foreach ($m in $urlMatches) {
        $name = $m.Groups[1].Value
        $url = $m.Groups[2].Value
        $localPath = Get-OrDownload-Wheel -Name $name -Url $url
        if ($localPath) { Invoke-CondaCommand "pip install `"$localPath`" $PIPargs" }
    }
}

# === 7. Clone & ComfyUI ===
Write-Step "Cloning ComfyUI and Installing Requirements..." 7 9
git clone https://github.com/comfyanonymous/ComfyUI $ComfyDir
Set-Location $ComfyDir
Invoke-CondaCommand "pip install -r requirements.txt $PIPargs"
Set-Location $ScriptPath

Write-Status "Installing Custom Nodes..." "INFO"
foreach ($node in $nodeList) {
    Write-Host "   > Cloning: $($node.name)" -ForegroundColor Cyan
    git clone $node.url "$ComfyDir\custom_nodes\$($node.name)" 2>$null | Out-Null

    $reqPath = "$ComfyDir\custom_nodes\$($node.name)\requirements.txt"
    if (Test-Path $reqPath) {
        Invoke-CondaCommand "pip install -r `"$reqPath`" --use-pep517 $PIPargs"
    }

    $installPath = "$ComfyDir\custom_nodes\$($node.name)\install.py"
    if (Test-Path $installPath) {
        Invoke-CondaCommand "python `"$installPath`""
    }
}

# === 8. Helper Files ===
Write-Step "Processing Helper Files..." 8 9
if (Test-Path "Supp.zip") {
    Write-Status "Extracting Supp.zip to ComfyUI directory..." "INFO"
    
    # Создаём временную папку для распаковки
    $tempExtractDir = Join-Path $env:TEMP "Supp_extract_$(Get-Random)"
    New-Item -ItemType Directory -Force -Path $tempExtractDir | Out-Null
    
    # Распаковываем архив во временную папку
    tar.exe -xf "Supp.zip" -C $tempExtractDir
    
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

# === 9. Install Trellis2 GGUF ===
Write-Step "Installing Trellis2 GGUF (Models and Wheels)..." 9 9

$TrellisScript = "Update\trellis2setup.py"
if (Test-Path $TrellisScript) {
    Write-Status "Running Trellis2 setup script..." "INFO"
    Invoke-CondaCommand "python `"$TrellisScript`""
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