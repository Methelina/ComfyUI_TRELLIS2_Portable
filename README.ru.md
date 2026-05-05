# ComfyUI TRELLIS2 Portable

Портативный инсталлятор для запуска **ComfyUI TRELLIS2 Portable** для генерации 3D через **TRELLIS2 (GGUF)** из коробки.

## 🚀 Быстрый старт

1. **Скачайте** репозиторий или выполните `git clone`
2. **Запустите** `Trellis2_portable.ps1` (PowerShell) или `Trellis2_portable_v5.1.ps1` (для устаревшей PowerShell 5.1 и старше)
3. **Дождитесь** автоматической установки окружения, зависимостей и моделей
4. **Отредактируйте** под свою конфигурацию компа `run_nvidia_gpu.ps1` и **запустите**. Или `run_nvidia_gpu_v5.1.ps1` (для устаревшей PowerShell 5.1 и старше)
5. Профит :)

## 📦 Что устанавливается?

- Python 3.12 через uv (astral-sh/uv) — менеджер загружается автоматически
- PyTorch 2.8 (CUDA 12.8)
- ComfyUI + пакет `ComfyUI-Trellis2-GGUF`
- Скомпилированый пакет flash_attn, Triton, XFormers
- Все необходимые wheels (`cumesh`, `nvdiffrast` и др.)
- Модели: .sft/.GGUF
- Сет рабочих WorkFlow от FotoSHAMAN

**Полный список кастомных нод:**
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

## 💻 Системные требования

- **ОС:** Windows 10/11
- **GPU:** NVIDIA RTX 3xxx (Инструкции sm85+) с поддержкой CUDA 12.8 (6+ GB VRAM)
- **Git:** [Скачать Git для Windows](https://git-scm.com/download/win)
- **PowerShell 7.x** для запуска скрипта установки и приложения [Download Powershell 7 for win](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows?view=powershell-7.6#msi) 

## 🧩 Структура

```
ComfyUI_TRELLIS2_Portable/
├── Trellis2_portable.ps1       # Главный установщик
├── Trellis2_portable_v5.1.ps1  # Главный установщик (для устаревшей PowerShell 5.1 и старше) 
├── run_nvidia_gpu.ps1          # Скрипт запуска
├── run_nvidia_gpu_v5.1.ps1     # Скрипт запуска (для устаревшей PowerShell 5.1 и старше)
├── settings.yaml               # Конфиг для установки
├── uv.exe                      # uv package manager (автозагрузка)
├── comfy_env/                  # Python-окружение (uv venv)
└── ComfyUI/                    # Программа и кастомные ноды
```

## 📝 Лицензия

Проект распространяется под лицензией **Apache 2.0**.
