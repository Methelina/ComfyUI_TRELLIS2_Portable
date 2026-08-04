@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
title ComfyUI TRELLIS2 Portable Installer v0.5.0
cd /d "%~dp0"

set "CacheDir=%~dp0.cache"
set "PixiHomeDir=%~dp0.pixi_home"
set "PixiEnvsDir=%~dp0.pixi_envs"
set "RattlerCacheDir=%CacheDir%\rattler"
set "UvCacheDir=%CacheDir%\uv"
set "HfCacheDir=%CacheDir%\huggingface"
set "PixiCacheDir=%CacheDir%\pixi"
set "ComfyTempDir=%CacheDir%\ComfyUI"

if not exist "!CacheDir!" mkdir "!CacheDir!"
if not exist "!PixiHomeDir!" mkdir "!PixiHomeDir!"
if not exist "!PixiEnvsDir!" mkdir "!PixiEnvsDir!"
if not exist "!RattlerCacheDir!" mkdir "!RattlerCacheDir!"
if not exist "!UvCacheDir!" mkdir "!UvCacheDir!"
if not exist "!HfCacheDir!" mkdir "!HfCacheDir!"
if not exist "!PixiCacheDir!" mkdir "!PixiCacheDir!"
if not exist "!ComfyTempDir!" mkdir "!ComfyTempDir!"

set "PIXI_HOME=!PixiHomeDir!"
set "PIXI_ENV_DIR=!PixiEnvsDir!"
set "PIXI_CACHE_DIR=!PixiCacheDir!"
set "RATTLER_CACHE_DIR=!RattlerCacheDir!"
set "UV_CACHE_DIR=!UvCacheDir!"
set "HF_HOME=!HfCacheDir!"
set "HF_HUB_DOWNLOAD_TIMEOUT=60"
set "PIXI_NO_VERSION_CHECK=1"

set "WheelsDir=%~dp0wheels"
set "PIPargs=--no-cache"
set "UvVersion=0.11.6"
set "UvZipUrl=https://releases.astral.sh/github/uv/releases/download/%UvVersion%/uv-x86_64-pc-windows-msvc.zip"
set "UvExePath=%~dp0uv.exe"
set "PixiBinDir=%~dp0Bin"
set "PixiExePath=!PixiBinDir!\pixi.exe"

if "%PROCESSOR_ARCHITECTURE%"=="AMD64" set "ARCH=x86_64-pc-windows-msvc"
if "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "ARCH=aarch64-pc-windows-msvc"
if "%PROCESSOR_ARCHITECTURE%"=="x86" set "ARCH=i686-pc-windows-msvc"

set "SettingsFile=%~dp0settings.yaml"
if not exist "!SettingsFile!" (
    echo ERROR: File !SettingsFile! not found!
    pause
    exit /b 1
)

echo.
echo [INFO] Downloading uv Package Manager (%UvVersion%)...
if not exist "!UvExePath!" (
    set "uvZip=%~dp0uv.zip"
    curl -L -o "!uvZip!" "!UvZipUrl!"
    if not exist "!uvZip!" (
        echo [ERROR] Download failed.
        pause
        exit /b 1
    )
    set "uvTmp=%~dp0uv_tmp"
    if exist "!uvTmp!" rd /s /q "!uvTmp!"
    mkdir "!uvTmp!"
    tar -xf "!uvZip!" -C "!uvTmp!"
    for /d %%d in ("!uvTmp!\*") do (
        copy /y "%%d\uv.exe" "!UvExePath!" >nul
        if exist "%%d\uvx.exe" copy /y "%%d\uvx.exe" "%~dp0uvx.exe" >nul 2>nul
    )
    if not exist "!UvExePath!" (
        for %%f in ("!uvTmp!\uv.exe") do copy /y "%%f" "!UvExePath!" >nul
        for %%f in ("!uvTmp!\uvx.exe") do copy /y "%%f" "%~dp0uvx.exe" >nul 2>nul
    )
    rd /s /q "!uvTmp!"
    del "!uvZip!" 2>nul
    echo [OK] uv %UvVersion% extracted.
) else (
    echo [OK] uv.exe already exists, skipping.
)

echo [INFO] Parsing settings.yaml...

for /f tokens^=2^ delims^=^" %%V in ('findstr /b /c:"python_version:" "!SettingsFile!"') do set "PV=%%V"
if not defined PV set "PV=3.12"

set "VARSFILE=%~dp0_vars.bat"
"!UvExePath!" run --no-project --python !PV! "%~dp0yaml_parse.py" "!SettingsFile!" > "!VARSFILE!"
if errorlevel 1 (
    echo [ERROR] Failed to parse settings.yaml!
    del "!VARSFILE!" 2>nul
    pause
    exit /b 1
)
call "!VARSFILE!"
del "!VARSFILE!" 2>nul

set "EnvName=%ENV_NAME%"
set "ComfyDir=%COMFY_DIR%"
set "PythonExePath=%~dp0%EnvName%\Scripts\python.exe"
set "EnvDirPath=%~dp0%EnvName%"

echo.
echo  ======================================================
echo.
echo    ██▓        ██▓    ██▓        ██▓
echo   ▓██▒              ▓██▒
echo   ▒██░              ▒██░
echo   ▒██░              ▒██░
echo   ░██████▒ ██▓  ██▓ ░██████▒ ██▓  ██▓
echo   ░ ▒░▓  ░ ▒▓▒  ▒▓▒ ░ ▒░▓  ░ ▒▓▒  ▒▓▒
echo   ░ ░ ▒  ░ ░▒   ░▒  ░ ░ ▒  ░ ░▒   ░▒
echo     ░ ░    ░    ░     ░ ░    ░    ░
echo       ░  ░  ░    ░      ░  ░  ░    ░
echo.
echo  ======================================================
echo    ComfyUI TRELLIS2 by Soror L.'.L.'.
echo    Portable Installer v0.5.0
echo  ======================================================
echo    env=%ENV_NAME%  python=%PYTHON_VERSION%  dir=%COMFY_DIR%
echo    wheels=%WHEEL_COUNT%  nodes=%NODE_COUNT%  pypi=%PYPI_COUNT%
echo  ======================================================
echo.

echo [INFO] Installing Pixi package manager into 'Bin' folder...
if not exist "!PixiExePath!" (
    set "BINARY=pixi-%ARCH%"
    set "DOWNLOAD_URL=https://github.com/prefix-dev/pixi/releases/latest/download/!BINARY!.zip"
    echo [INFO] Downloading Pixi from !DOWNLOAD_URL!...
    set "pixiZip=%~dp0pixi.zip"
    curl -L -o "!pixiZip!" "!DOWNLOAD_URL!"
    if not exist "!pixiZip!" (
        echo [ERROR] Download failed.
        pause
        exit /b 1
    )
    if not exist "!PixiBinDir!" mkdir "!PixiBinDir!"
    tar -xf "!pixiZip!" -C "!PixiBinDir!"
    del "!pixiZip!" 2>nul
    if not exist "!PixiExePath!" (
        for /r "!PixiBinDir!" %%f in (pixi.exe) do move /y "%%f" "!PixiExePath!" >nul 2>nul
        for /d %%d in ("!PixiBinDir!\*") do rd /s /q "%%d" 2>nul
    )
    if not exist "!PixiExePath!" (
        echo [ERROR] pixi.exe not found after extraction. Installation failed.
        pause
        exit /b 1
    )
    echo [OK] Pixi downloaded and extracted to !PixiBinDir!
) else (
    echo [OK] Pixi already exists at !PixiExePath!, skipping download.
)

set "PATH=!PixiBinDir!;%PATH%"
echo [OK] Added !PixiBinDir! to PATH for this session.
for /f "tokens=*" %%i in ('"!PixiExePath!" --version 2^>^&1') do echo [OK] Pixi version: %%i

echo.
echo >>> Stage [1/10]: Checking Dependencies (Git)...
where git >nul 2>nul
if errorlevel 1 (
    echo [ERROR] CRITICAL ERROR: Missing dependencies.
    echo Not installed: Git
    echo Please install them manually and restart.
    pause
    exit /b 1
)
echo [OK] Dependencies found.

echo.
echo >>> Stage [2/10]: Checking Directory Structure...
if exist "!EnvDirPath!" (
    echo [WARN] Environment folder '!EnvName!' already exists.
    set /p ans="Delete and recreate? (Y/N): "
    if /i "!ans!"=="Y" (
        rd /s /q "!EnvDirPath!"
    ) else (
        echo [ERROR] Installation aborted.
        pause
        exit /b 1
    )
)
if exist "%~dp0!ComfyDir!" (
    echo [WARN] Folder '!ComfyDir!' already exists.
    echo Please delete folder '!ComfyDir!' for a clean install.
    pause
    exit /b 1
)

echo.
echo >>> Stage [3/10]: Creating Python Environment with uv (!EnvName!)...
"!UvExePath!" venv "!EnvDirPath!" --python %PYTHON_VERSION%
if errorlevel 1 (
    echo [ERROR] Failed to create environment.
    pause
    exit /b 1
)
set "pythonTarget=!EnvDirPath!\Scripts\python.exe"
set "pythonLink=!EnvDirPath!\python.exe"
if not exist "!pythonLink!" (
    mklink /h "!pythonLink!" "!pythonTarget!" >nul 2>&1
    if errorlevel 1 (
        echo @^"%%~dp0Scripts\python.exe^" %%* > "!pythonLink!"
        echo [WARN] Created .bat wrapper: python.exe -^> Scripts\python.exe (hardlink unavailable)
    ) else (
        echo [OK] Created hardlink: python.exe -^> Scripts\python.exe
    )
)
echo [OK] Environment created.

echo.
echo >>> Stage [4/10]: Installing PyTorch (Torch 2.8 + Vision 0.23 + Audio 2.8)...
"!UvExePath!" pip install --python "!PythonExePath!" torch==2.8.0+cu128 torchvision==0.23.0+cu128 torchaudio==2.8.0+cu128 --extra-index-url https://download.pytorch.org/whl/cu128 %PIPargs%
if errorlevel 1 echo [WARN] PyTorch install returned code !ERRORLEVEL!

echo.
echo >>> Stage [5/10]: Installing Specific Wheels...
if !WHEEL_COUNT! gtr 0 (
    if not exist "!WheelsDir!" mkdir "!WheelsDir!"
    for /l %%i in (1,1,!WHEEL_COUNT!) do call :process_wheel %%i
) else (
    echo [INFO] No wheels configured.
)

"!UvExePath!" pip install --python "!PythonExePath!" pygit2 %PIPargs%

echo.
echo >>> Stage [6/10]: Installing PyPI Packages...
if !PYPI_COUNT! gtr 0 (
    for /l %%i in (1,1,!PYPI_COUNT!) do call :process_pypi %%i
) else (
    echo [INFO] No PyPI packages configured.
)

echo.
echo >>> Stage [7/10]: Cloning ComfyUI and Installing Requirements...
git clone https://github.com/comfyanonymous/ComfyUI "!ComfyDir!" 2>nul
if not exist "%~dp0!ComfyDir!" (
    echo [ERROR] Failed to clone ComfyUI.
    pause
    exit /b 1
)
cd /d "%~dp0!ComfyDir!"
"!UvExePath!" pip install --python "!PythonExePath!" -r "requirements.txt" %PIPargs%
cd /d "%~dp0"

echo [INFO] Installing Custom Nodes...
if !NODE_COUNT! gtr 0 (
    for /l %%i in (1,1,!NODE_COUNT!) do call :process_node %%i
) else (
    echo [INFO] No custom nodes configured.
)

echo.
echo >>> Stage [8/10]: Processing Helper Files...
if exist "%~dp0Supp.tar.gz" (
    echo [INFO] Extracting Supp.tar.gz to ComfyUI directory...
    set "tempExtract=!TEMP!\Supp_extract_!RANDOM!"
    mkdir "!tempExtract!"
    tar -xzf "%~dp0Supp.tar.gz" -C "!tempExtract!"
    if exist "!tempExtract!\Supp\ComfyUI" (
        xcopy /e /y "!tempExtract!\Supp\ComfyUI\*" "%~dp0!ComfyDir!\" >nul
        echo [OK] Helper files merged into !ComfyDir!
    ) else (
        echo [WARN] Warning: Expected structure Supp/ComfyUI not found in archive
    )
    rd /s /q "!tempExtract!"
)

set "sitePkgs=%~dp0!EnvName!\Lib\site-packages"

if exist "%~dp0update\xformers-0.0.33.tar.gz" (
    echo [INFO] Extracting xformers-0.0.33.tar.gz to Python environment...
    if not exist "!sitePkgs!" mkdir "!sitePkgs!"
    tar -xzf "%~dp0update\xformers-0.0.33.tar.gz" -C "!sitePkgs!"
    echo [OK] xformers installed to !sitePkgs!
) else (
    echo [WARN] xformers-0.0.33.tar.gz not found in update/, skipping...
)

if exist "%~dp0update\flash_attn-2.8.2.tar.gz" (
    echo [INFO] Extracting flash_attn-2.8.2.tar.gz to Python environment...
    if not exist "!sitePkgs!" mkdir "!sitePkgs!"
    tar -xzf "%~dp0update\flash_attn-2.8.2.tar.gz" -C "!sitePkgs!"
    echo [OK] flash_attn installed to !sitePkgs!
) else (
    echo [WARN] flash_attn-2.8.2.tar.gz not found in update/, skipping...
)

echo.
echo >>> Stage [9/10]: Installing Trellis2 GGUF (Models and Wheels)...
if exist "%~dp0Update\trellis2setup.py" (
    echo [INFO] Running Trellis2 setup script...
    "!PythonExePath!" "%~dp0Update\trellis2setup.py"
) else (
    echo [WARN] Trellis2 setup script not found at Update\trellis2setup.py
)

echo.
echo >>> Stage [10/10]: Installing FaithContouring and Pulse-MeshAudit...
if exist "%~dp0Update\Faith-Pulse_install.py" (
    echo [INFO] Running Faith+Pulse setup script...
    "!PythonExePath!" "%~dp0Update\Faith-Pulse_install.py"
) else (
    echo [WARN] Faith+Pulse script not found at Update\Faith-Pulse_install.py
)

echo.
echo ╔══════════════════════════════════════════════════════════════╗
echo ║                INSTALLATION COMPLETE                         ║
echo ╚══════════════════════════════════════════════════════════════╝
echo.
pause
goto :eof

:process_wheel
setlocal
call set "wn=%%WHEEL_%1_NAME%%"
call set "wu=%%WHEEL_%1_URL%%"
call set "wd=%%WHEEL_%1_NODEPS%%"
for %%f in ("!wu!") do set "wfn=%%~nxf"
set "wlocal=!WheelsDir!\!wfn!"
if exist "!wlocal!" (
    echo    [CACHE] !wn! found locally.
) else (
    echo    [DOWN]  Downloading !wn!...
    curl -L -o "!wlocal!" "!wu!"
    if not exist "!wlocal!" (
        echo    [ERR]   Error downloading !wn!
        endlocal
        exit /b 1
    )
    echo    [OK]    !wn! downloaded.
)
set "depsFlag="
if /i "!wd!"=="true" set "depsFlag=--no-deps"
"!UvExePath!" pip install --python "!PythonExePath!" "!wlocal!" !depsFlag! %PIPargs%
endlocal
exit /b 0

:process_node
setlocal
call set "nu=%%NODE_%1_URL%%"
call set "nn=%%NODE_%1_NAME%%"
echo    ^> Cloning: !nn!
set "nodeDir=%~dp0!ComfyDir!\custom_nodes\!nn!"
git clone "!nu!" "!nodeDir!" 2>nul
if exist "!nodeDir!\requirements.txt" (
    "!UvExePath!" pip install --python "!PythonExePath!" -r "!nodeDir!\requirements.txt" %PIPargs%
)
set "hasToml="
for %%f in ("!nodeDir!\comfy-env*.toml") do set "hasToml=1"
if defined hasToml (
    set "tomlNames="
    for %%f in ("!nodeDir!\comfy-env*.toml") do if defined tomlNames (set "tomlNames=!tomlNames!, %%~nxf") else (set "tomlNames=%%~nxf")
    echo    [Pixie] Comfy-Env file(s) detected at "!nn!": !tomlNames!
    echo    [Pixie] Create Comfy-Env Ignored - you can setup it later via "Comfy-Env_Setup.bat"
) else (
    if exist "!nodeDir!\install.py" (
        "!PythonExePath!" "!nodeDir!\install.py"
    )
)
endlocal
exit /b 0

:process_pypi
setlocal
call set "pn=%%PYPI_%1_NAME%%"
call set "pu=%%PYPI_%1_URL%%"
if defined pu if not "!pu!"=="" (
    for %%f in ("!pu!") do set "pfn=%%~nxf"
    set "plocal=!WheelsDir!\!pfn!"
    if not exist "!plocal!" (
        echo    [DOWN]  Downloading !pn!...
        curl -L -o "!plocal!" "!pu!"
        echo    [OK]    !pn! downloaded.
    )
    "!UvExePath!" pip install --python "!PythonExePath!" "!plocal!" %PIPargs%
) else (
    "!UvExePath!" pip install --python "!PythonExePath!" "!pn!" %PIPargs%
)
endlocal
exit /b 0
