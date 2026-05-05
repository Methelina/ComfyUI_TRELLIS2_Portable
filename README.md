# ComfyUI TRELLIS2 Portable

A portable installer for running **ComfyUI TRELLIS2 Portable** for 3D generation via **TRELLIS2 (GGUF)** out of the box.

## 🚀 Quick Start

1. **Download** the repository or run `git clone`
2. **Launch** `Trellis2_portable.ps1` (PowerShell) to install the software and all dependencies. For depricated and old PowerShell 5.1 or less use `Trellis2_portable_v5.1`.
3. **Wait** for the automatic installation of the environment, dependencies, and models
4. **Edit** `run_nvidia_gpu.ps1` to match your PC configuration and **run** it. For depricated and old PowerShell 5.1 or less use `run_nvidia_gpu_v5.1`
5. Profit :)

## 📦 What Gets Installed?

- Python 3.12 via uv (astral-sh/uv) — the manager is downloaded automatically
- PyTorch 2.8 (CUDA 12.8)
- ComfyUI + `ComfyUI-Trellis2-GGUF` package
- Compiled `flash_attn`, `Triton`, `XFormers`
- All required wheels (`cumesh`, `nvdiffrast`, etc.)
- Models: `.sft / .GGUF`
- Proper WorlFlow-Set by `FotoSHAMAN`.

**Full list of custom nodes:**

```
custom_nodes/
├───comfyui-manager
├───was-node-suite-comfyui
├───ComfyUI-GGUF
├───ComfyUI-Trellis2-GGUF
├───ComfyUI-RMBG
├───ComfyUI-GeometryPack
├───ComfyUI-Env-Manager
├───ComfyUI-Pulse-MeshAudit
├───ComfyUI-Easy-Use
├───comfyui_controlnet_aux
├───ComfyUI_Comfyroll_CustomNodes
├───ComfyUI-Crystools
├───rgthree-comfy
├───ComfyUI-Florence2
├───ComfyUI_Searge_LLM
├───controlaltai-nodes
├───comfyui-ollama
├───comfyui-itools
├───comfyui-seamless-tiling
├───comfyui-inpaint-cropandstitch
├───canvas_tab
├───ComfyUI-OmniGen
├───comfyui-inspyrenet-rembg
├───ComfyUI_AdvancedRefluxControl
├───comfyui-videohelpersuite
├───comfyui-advancedliveportrait
├───ComfyUI-ToSVG
├───comfyui-kokoro
├───janus-pro
├───ComfyUI_Sonic
├───kaytool
├───ComfyUI-TiledDiffusion
├───ComfyUI-LTXVideo
├───comfyui-kjnodes
└───cg-use-everywhere
```

## 💻 System Requirements

- **OS:** Windows 10/11
- **GPU:** NVIDIA RTX 3xxx (sm85+ instructions) with CUDA 12.8 support (6+ GB VRAM)
- **Git:** [Download Git for Windows](https://git-scm.com/download/win)
- **PowerShell 7.x** to run the script [Download Powershell 7 for win](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows?view=powershell-7.6#msi) 

## 🧩 Directory Structure

```
ComfyUI_TRELLIS2_Portable/
├── Trellis2_portable.ps1       # Main installer
├── Trellis2_portable_v5.1.ps1  # Main installer (for outdated PowerShell 5.1 or less) 
├── run_nvidia_gpu.ps1          # Launch script
├── run_nvidia_gpu_v5.1.ps1     # Launch script (for outdated PowerShell 5.1 or less)
├── settings.yaml               # Installation config
├── uv.exe                      # uv package manager (auto-download)
├── comfy_env/                  # Python environment (uv venv)
└── ComfyUI/                    # Application and custom nodes
```

## 📝 License

This project is distributed under the **Apache 2.0** license.
