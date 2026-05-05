# ==========================================
# ComfyUI Installer v0.5.0 (PS 5.1 Safe Build)
# ==========================================
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ProgressPreference = 'SilentlyContinue'

$ScriptPath = $PSScriptRoot
if (-not $ScriptPath) { $ScriptPath = '.' }
Set-Location $ScriptPath

# === PORTABILITY ISOLATION BLOCK ===
$CacheDir        = Join-Path $ScriptPath '.cache'
$PixiHomeDir     = Join-Path $ScriptPath '.pixi_home'
$PixiEnvsDir     = Join-Path $ScriptPath '.pixi_envs'
$RattlerCacheDir = Join-Path $CacheDir 'rattler'
$UvCacheDir      = Join-Path $CacheDir 'uv'
$HfCacheDir      = Join-Path $CacheDir 'huggingface'
$PixiCacheDir    = Join-Path $CacheDir 'pixi'
$ComfyTempDir    = Join-Path $CacheDir 'ComfyUI'

@($CacheDir, $PixiHomeDir, $PixiEnvsDir, $RattlerCacheDir, $UvCacheDir,
  $HfCacheDir, $PixiCacheDir, $ComfyTempDir) | ForEach-Object {
    if (-not (Test-Path $_)) { New-Item -ItemType Directory -Force -Path $_ | Out-Null }
}

$env:PIXI_HOME = $PixiHomeDir
$env:PIXI_ENV_DIR = $PixiEnvsDir
$env:PIXI_CACHE_DIR = $PixiCacheDir
$env:RATTLER_CACHE_DIR = $RattlerCacheDir
$env:UV_CACHE_DIR = $UvCacheDir
$env:HF_HOME = $HfCacheDir
$env:HF_HUB_DOWNLOAD_TIMEOUT = '60'
$env:PIXI_NO_VERSION_CHECK = '1'

# === Vars & Config ===
$SettingsFile = 'settings.yaml'
$WheelsDir    = 'wheels'
if (-not (Test-Path $SettingsFile)) {
    Write-Host ('ERROR: File ' + $SettingsFile + ' not found!') -ForegroundColor Red; exit 1
}
$yamlText = Get-Content $SettingsFile -Raw

# Safe quote char for regex (bypasses clipboard corruption)
$Q = [char]34

$config = @{}
$config['env_name']       = if ($yamlText -match ('env_name:\s*' + $Q + '([^' + $Q + ']+)' + $Q)) { $matches[1] } else { 'comfy_env' }
$config['python_version'] = if ($yamlText -match ('python_version:\s*' + $Q + '([^' + $Q + ']+)' + $Q)) { $matches[1] } else { '3.12' }
$config['comfy_dir']      = if ($yamlText -match ('comfy_dir:\s*' + $Q + '([^' + $Q + ']+)' + $Q)) { $matches[1] } else { 'ComfyUI' }

$nodeList = @()
$nodesPattern = 'nodes:\s*([\s\S]*?)(?=wheels:|pypi_packages:|\Z)'
if ($yamlText -match $nodesPattern) {
    $nodeBlock = $matches[1]
    $nodeRegex = '- url:\s*' + $Q + '([^' + $Q + ']+)' + $Q + '\s*name:\s*' + $Q + '([^' + $Q + ']+)' + $Q
    [regex]::Matches($nodeBlock, $nodeRegex) | ForEach-Object {
        $nodeList += @{ url = $_.Groups[1].Value; name = $_.Groups[2].Value }
    }
}

$wheelList = @{}
$wheelsPattern = 'wheels:\s*([\s\S]*?)(?=nodes:|pypi_packages:|\Z)'
if ($yamlText -match $wheelsPattern) {
    $wheelBlock = $matches[1]
    $entries = $wheelBlock -split '  [a-z_]+: ', 0, [System.StringSplitOptions]::RemoveEmptyEntries | Where-Object { $_ -match 'url:' }
    foreach ($entry in $entries) {
        $wPattern = '^\s*([a-z_]+):\s*\n\s+url:\s*' + $Q + '([^' + $Q + ']+)' + $Q + '\s+no_deps:\s*(true|false)'
        if ($entry -match $wPattern) {
            $wheelList[$matches[1]] = @{ url = $matches[2]; no_deps = ($matches[3] -eq 'true') }
        }
    }
}

$EnvName       = $config['env_name']
$ComfyDir      = $config['comfy_dir']
$UvVersion     = '0.11.6'
$UvZipUrl      = 'https://releases.astral.sh/github/uv/releases/download/' + $UvVersion + '/uv-x86_64-pc-windows-msvc.zip'
$UvExePath     = Join-Path $ScriptPath 'uv.exe'
$PythonExePath = Join-Path $ScriptPath ($EnvName + '\Scripts\python.exe')
$PIPargs       = '--no-cache'

# === Functions ===
function Write-Status {
    param([string]$Message, [string]$Type = 'INFO')
    $prefix = switch ($Type) { 'INFO' { '[INFO]   ' }; 'WARN' { '[WARN]   ' }; 'ERROR' { '[ERROR]  ' }; 'SUCCESS' { '[OK]     ' }; default { '[INFO]   ' } }
    $color  = switch ($Type) { 'INFO' { 'Cyan' }; 'WARN' { 'Yellow' }; 'ERROR' { 'Red' }; 'SUCCESS' { 'Green' }; default { 'White' } }
    Write-Host ($prefix + $Message) -ForegroundColor $color
}

function Write-Step {
    param([string]$Message, [int]$Step, [int]$Total)
    Write-Host ''
    Write-Host ('>>> Stage [' + $Step + '/' + $Total + ']: ' + $Message) -ForegroundColor Magenta
}

function Test-Command { param([string]$Cmd); return $null -ne (Get-Command $Cmd -ErrorAction SilentlyContinue) }

function Invoke-UvPipInstall {
    param([string]$Command)
    Write-Host ('   > uv pip install ' + $Command) -ForegroundColor DarkGray
    $process = Start-Process -FilePath $UvExePath -ArgumentList ('pip install --python "' + $PythonExePath + '" ' + $Command) -NoNewWindow -Wait -PassThru
    if ($process.ExitCode -ne 0) { Write-Status ('Execution failed (code ' + $process.ExitCode + ')') 'ERROR' }
    return $process.ExitCode
}

function Invoke-PythonCommand {
    param([string]$Command)
    Write-Host ('   > python ' + $Command) -ForegroundColor DarkGray
    $process = Start-Process -FilePath $PythonExePath -ArgumentList $Command -NoNewWindow -Wait -PassThru
    if ($process.ExitCode -ne 0) { Write-Status ('Execution failed (code ' + $process.ExitCode + ')') 'ERROR' }
    return $process.ExitCode
}

function Get-OrDownload-Wheel {
    param([string]$Name, [string]$Url)
    $fileName  = [System.IO.Path]::GetFileName($Url)
    $localPath = Join-Path $ScriptPath $WheelsDir
    $filePath  = Join-Path $localPath $fileName
    if (-not (Test-Path $localPath)) { New-Item -ItemType Directory -Force -Path $localPath | Out-Null }
    if (Test-Path $filePath) { Write-Host ('   [CACHE] ' + $Name + ' found locally.') -ForegroundColor Gray }
    else {
        Write-Host ('   [DOWN]  Downloading ' + $Name + '...') -ForegroundColor Yellow
        try {
            Invoke-WebRequest -Uri $Url -OutFile $filePath -ErrorAction Stop
            Write-Host ('   [OK]    ' + $Name + ' downloaded.') -ForegroundColor Green
        } catch {
            Write-Host ('   [ERR]   Error downloading ' + $Name + ' : ' + $_) -ForegroundColor Red; return $null
        }
    }
    return $filePath
}

function Get-TargetTriple() {
    if ([Environment]::Is64BitOperatingSystem) { return 'x86_64-pc-windows-msvc' }
    else { return 'i686-pc-windows-msvc' }
}

# === Header ===
Write-Host ' ========================================== ' -ForegroundColor Green
Write-Host '  ComfyUI TRELLIS2 by Soror L.'.L.'.        ' -ForegroundColor Yellow
Write-Host '  Portable Installer v0.5.0                 ' -ForegroundColor Green
Write-Host ' ========================================== ' -ForegroundColor Green; Write-Host ''

# === 0. Download uv ===
Write-Step ('Downloading uv Package Manager (' + $UvVersion + ')...') 0 10
if (-not (Test-Path $UvExePath)) {
    $uvZip = Join-Path $ScriptPath 'uv.zip'
    Write-Status ('Downloading uv ' + $UvVersion + '...') 'INFO'
    try { Invoke-WebRequest -Uri $UvZipUrl -OutFile $uvZip -ErrorAction Stop }
    catch { Write-Status ('Download failed: ' + $_.Exception.Message) 'ERROR'; Remove-Item $uvZip -Force -ErrorAction SilentlyContinue; Read-Host 'Press Enter to exit'; exit 1 }
    if ((Test-Path $uvZip) -and (Get-Item $uvZip).Length -lt 1000) {
        Write-Status 'Downloaded file is too small, likely an error page.' 'ERROR'
        Remove-Item $uvZip -Force -ErrorAction SilentlyContinue; Read-Host 'Press Enter to exit'; exit 1
    }
    $uvTmp = Join-Path $ScriptPath 'uv_tmp'
    if (Test-Path $uvTmp) { Remove-Item $uvTmp -Recurse -Force }
    Expand-Archive -Path $uvZip -DestinationPath $uvTmp -Force
    $extractedDir = Get-ChildItem -Path $uvTmp -Directory | Select-Object -First 1
    if (-not $extractedDir) { $extractedDir = @{ FullName = $uvTmp } }
    Copy-Item (Join-Path $extractedDir.FullName 'uv.exe') $UvExePath
    Copy-Item (Join-Path $extractedDir.FullName 'uvx.exe') (Join-Path $ScriptPath 'uvx.exe') -ErrorAction SilentlyContinue
    Remove-Item $uvTmp -Recurse -Force; Remove-Item $uvZip -Force
    Write-Status ('uv ' + $UvVersion + ' extracted successfully.') 'SUCCESS'
} else { Write-Status 'uv.exe already exists, skipping download.' 'SUCCESS' }

# === 0b. Pixi ===
Write-Status 'Installing Pixi package manager into Bin folder...' 'INFO'
$PixiBinDir  = Join-Path $ScriptPath 'Bin'
$PixiExePath = Join-Path $PixiBinDir 'pixi.exe'
if (-not (Test-Path $PixiExePath)) {
    $ARCH = Get-TargetTriple
    if (-not @('x86_64-pc-windows-msvc', 'aarch64-pc-windows-msvc') -contains $ARCH) {
        Write-Status ('Unsupported architecture for Pixi: ' + $ARCH) 'ERROR'; Read-Host 'Press Enter to exit'; exit 1
    }
    $BINARY = 'pixi-' + $ARCH
    $DOWNLOAD_URL = 'https://github.com/prefix-dev/pixi/releases/latest/download/' + $BINARY + '.zip'
    Write-Status ('Downloading Pixi from ' + $DOWNLOAD_URL + '...') 'INFO'
    $pixiZip = Join-Path $ScriptPath 'pixi.zip'
    try { Invoke-WebRequest -Uri $DOWNLOAD_URL -OutFile $pixiZip -ErrorAction Stop }
    catch { Write-Status ('Download failed: ' + $_.Exception.Message) 'ERROR'; Remove-Item $pixiZip -Force -ErrorAction SilentlyContinue; Read-Host 'Press Enter to exit'; exit 1 }
    if ((Test-Path $pixiZip) -and (Get-Item $pixiZip).Length -lt 1000) {
        Write-Status 'Downloaded file is too small.' 'ERROR'; Remove-Item $pixiZip -Force -ErrorAction SilentlyContinue; Read-Host 'Press Enter to exit'; exit 1
    }
    if (-not (Test-Path $PixiBinDir)) { New-Item -ItemType Directory -Force -Path $PixiBinDir | Out-Null }
    Expand-Archive -Path $pixiZip -DestinationPath $PixiBinDir -Force
    Remove-Item $pixiZip -Force
    if (-not (Test-Path $PixiExePath)) {
        $extractedPixi = Get-ChildItem -Path $PixiBinDir -Filter 'pixi.exe' -Recurse | Select-Object -First 1
        if ($extractedPixi) {
            Move-Item -Path $extractedPixi.FullName -Destination $PixiExePath -Force
            Get-ChildItem -Path $PixiBinDir -Directory | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        } else {
            Write-Status 'pixi.exe not found after extraction.' 'ERROR'; Read-Host 'Press Enter to exit'; exit 1
        }
    }
    Write-Status ('Pixi downloaded and extracted to ' + $PixiBinDir) 'SUCCESS'
} else { Write-Status 'Pixi already exists, skipping download.' 'SUCCESS' }

$env:Path = $PixiBinDir + ';' + $env:Path
Write-Status ('Added ' + $PixiBinDir + ' to PATH for this session.') 'SUCCESS'

try { $pixiVersionOutput = & $PixiExePath --version; Write-Status ('Pixi version: ' + $pixiVersionOutput) 'SUCCESS' }
catch { Write-Status 'Failed to execute pixi.exe.' 'ERROR'; Read-Host 'Press Enter to exit'; exit 1 }

# === 1-3. Deps, Folders, Env ===
Write-Step 'Checking Dependencies (Git)...' 1 10
$Missing = @(); if (!(Test-Command 'git')) { $Missing += 'Git' }
if ($Missing.Count -gt 0) { Write-Status 'CRITICAL ERROR: Missing Git.' 'ERROR'; Read-Host 'Press Enter to exit'; exit 1 }
Write-Status 'Dependencies found.' 'SUCCESS'

Write-Step 'Checking Directory Structure...' 2 10
if (Test-Path $EnvName) {
    Write-Status ('Environment folder ' + $EnvName + ' already exists.') 'WARN'
    $ans = Read-Host 'Delete and recreate? (Y/N)'
    if ($ans -eq 'Y' -or $ans -eq 'y') { Remove-Item -Path $EnvName -Recurse -Force }
    else { Write-Status 'Installation aborted.' 'ERROR'; exit 1 }
}
if (Test-Path $ComfyDir) { Write-Status ('Folder ' + $ComfyDir + ' already exists.') 'WARN'; Read-Host 'Press Enter to exit'; exit 1 }

Write-Step ('Creating Python Environment with uv (' + $EnvName + ')...') 3 10
$EnvDirPath = Join-Path $ScriptPath $EnvName
& $UvExePath venv $EnvDirPath --python $config['python_version']
if ($LASTEXITCODE -ne 0) { Write-Status 'Failed to create environment.' 'ERROR'; exit 1 }

$pythonTarget = Join-Path $EnvDirPath 'Scripts\python.exe'
$pythonLink   = Join-Path $EnvDirPath 'python.exe'
if (-not (Test-Path $pythonLink)) {
    try { New-Item -ItemType HardLink -Path $pythonLink -Target $pythonTarget -ErrorAction Stop | Out-Null; Write-Status 'Created hardlink: python.exe' 'SUCCESS' }
    catch {
        $batPath = Join-Path $EnvDirPath 'python.cmd'
        Set-Content -Path $batPath -Value ("@echo off`n" + '"' + '%~dp0Scripts\python.exe"' + ' %*') -Encoding ASCII -Force
        Write-Status 'Created fallback wrapper: python.cmd' 'WARN'
    }
}
Write-Status 'Environment created.' 'SUCCESS'

# === 4. PyTorch ===
Write-Step 'Installing PyTorch (Torch 2.8 + cu128)...' 4 10
$TorchCmd = 'torch==2.8.0+cu128 torchvision==0.23.0+cu128 torchaudio==2.8.0+cu128 --extra-index-url https://download.pytorch.org/whl/cu128'
Invoke-UvPipInstall $TorchCmd

# === 5. Wheels ===
Write-Step 'Installing Specific Wheels...' 5 10
foreach ($key in $wheelList.Keys) {
    $info = $wheelList[$key]
    $localWheelPath = Get-OrDownload-Wheel -Name $key -Url $info.url
    if ($localWheelPath) {
        $depsFlag = if ($info.no_deps) { '--no-deps' } else { '' }
        Invoke-UvPipInstall ('"' + $localWheelPath + '" ' + $depsFlag + ' ' + $PIPargs)
    } else { Write-Status ('Skipping ' + $key + ' due to download error.') 'WARN' }
}
Invoke-UvPipInstall ('pygit2 ' + $PIPargs)

# === 6. PyPI Packages ===
Write-Step 'Installing PyPI Packages...' 6 10
$pypiPattern = 'pypi_packages:\s*([\s\S]*?)(?=\Z|wheels:|nodes:)'
if ($yamlText -match $pypiPattern) {
    $pypiBlock = $matches[1]
    $simplePattern = '- name:\s*' + $Q + '([a-zA-Z0-9_-]+)' + $Q + '(?!\s+url:)'
    $urlPattern    = '- name:\s*' + $Q + '([a-zA-Z0-9_-]+)' + $Q + '\s+url:\s*' + $Q + '([^' + $Q + ']+)' + $Q
    
    [regex]::Matches($pypiBlock, $simplePattern) | ForEach-Object {
        Invoke-UvPipInstall ($_.Groups[1].Value + ' ' + $PIPargs)
    }
    [regex]::Matches($pypiBlock, $urlPattern) | ForEach-Object {
        $name = $_.Groups[1].Value; $url = $_.Groups[2].Value
        $localPath = Get-OrDownload-Wheel -Name $name -Url $url
        if ($localPath) { Invoke-UvPipInstall ('"' + $localPath + '" ' + $PIPargs) }
    }
}

# === 7. ComfyUI & Nodes ===
Write-Step 'Cloning ComfyUI and Installing Requirements...' 7 10
git clone https://github.com/comfyanonymous/ComfyUI $ComfyDir
Set-Location $ComfyDir
Invoke-UvPipInstall ('-r "requirements.txt" ' + $PIPargs)
Set-Location $ScriptPath

Write-Status 'Installing Custom Nodes...' 'INFO'
foreach ($node in $nodeList) {
    Write-Host ('   > Cloning: ' + $node.name) -ForegroundColor Cyan
    git clone $node.url ($ComfyDir + '\custom_nodes\' + $node.name) 2>$null | Out-Null
    $nodeDir = $ComfyDir + '\custom_nodes\' + $node.name
    $reqPath = Join-Path $nodeDir 'requirements.txt'
    if (Test-Path $reqPath) { Invoke-UvPipInstall ('-r "' + $reqPath + '" ' + $PIPargs) }
    
    $comfyEnvTomlFiles = Get-ChildItem -Path $nodeDir -Filter 'comfy-env*.toml' -ErrorAction SilentlyContinue
    if ($comfyEnvTomlFiles) {
        $fileNames = ($comfyEnvTomlFiles.Name) -join ', '
        Write-Host ('   [Pixie] Comfy-Env detected at ' + $node.name + ': ' + $fileNames) -ForegroundColor Yellow
        Write-Host '   [Pixie] Setup skipped. Use Comfy-Env_Setup.bat later.' -ForegroundColor Yellow
    } else {
        $installPath = Join-Path $nodeDir 'install.py'
        if (Test-Path $installPath) { Invoke-PythonCommand ('"' + $installPath + '"') }
    }
}

# === 8. Helper Files ===
Write-Step 'Processing Helper Files...' 8 10
if (Test-Path 'Supp.tar.gz') {
    Write-Status 'Extracting Supp.tar.gz...' 'INFO'
    $tempExtractDir = Join-Path $env:TEMP ('Supp_extract_' + (Get-Random))
    New-Item -ItemType Directory -Force -Path $tempExtractDir | Out-Null
    tar.exe -xzf 'Supp.tar.gz' -C $tempExtractDir
    $sourceSupp = Join-Path $tempExtractDir 'Supp\ComfyUI'
    if (Test-Path $sourceSupp) { Copy-Item -Path ($sourceSupp + '\*') -Destination $ComfyDir -Recurse -Force; Write-Status 'Helper files merged.' 'SUCCESS' }
    else { Write-Status 'Warning: Expected structure not found' 'WARN' }
    Remove-Item -Path $tempExtractDir -Recurse -Force
}

$sitePackagesPath = 'comfy_env\Lib\site-packages'
foreach ($tarFile in @('update\xformers-0.0.33.tar.gz', 'update\flash_attn-2.8.2.tar.gz')) {
    if (Test-Path $tarFile) {
        Write-Status ('Extracting ' + (Split-Path $tarFile -Leaf) + '...') 'INFO'
        if (-not (Test-Path $sitePackagesPath)) { New-Item -ItemType Directory -Force -Path $sitePackagesPath | Out-Null }
        tar.exe -xzf $tarFile -C $sitePackagesPath
        Write-Status ('Installed to ' + $sitePackagesPath) 'SUCCESS'
    } else { Write-Status ((Split-Path $tarFile -Leaf) + ' not found, skipping...') 'WARN' }
}

# === 9. Trellis2 ===
Write-Step 'Installing Trellis2 GGUF...' 9 10
$TrellisScript = 'Update\trellis2setup.py'
if (Test-Path $TrellisScript) { Write-Status 'Running Trellis2 setup...' 'INFO'; Invoke-PythonCommand ('"' + $TrellisScript + '"') }
else { Write-Status 'Trellis2 setup script not found' 'WARN' }

# === Finish ===
Write-Host ''
Write-Host '╔══════════════════════════════════════════════════════════════╗' -ForegroundColor Green
Write-Host '║                INSTALLATION COMPLETE                         ║' -ForegroundColor Green
Write-Host '╚══════════════════════════════════════════════════════════════╝' -ForegroundColor Green
Write-Host ''
Read-Host 'Press Enter to exit'