# ComfyUI TRELLIS2 Portable

Портативный инсталлятор для запуска **ComfyUI TRELLIS2 Portable** для генерации 3D через **TRELLIS2 (GGUF)** из коробки.

## 🚀 Быстрый старт

1. **Скачайте** репозиторий или выполните `git clone`
2. **Запустите** `Trellis2_portable.ps1` (PowerShell)
3. **Дождитесь** автоматической установки окружения, зависимостей и моделей
4. **Отредактируйте** под свою конфигурацию компа `run_nvidia_gpu.bat` и **запустите**
5. Профит :)

## 📦 Что устанавливается?

- Python 3.12 через uv (astral-sh/uv) — менеджер загружается автоматически
- PyTorch 2.8 (CUDA 12.8)
- ComfyUI + кастомная нода `ComfyUI-Trellis2-GGUF`
- Все необходимые wheels (`cumesh`, `nvdiffrast` и др.)
- Модели: .sft/.GGUF

## 💻 Системные требования

- **ОС:** Windows 10/11
- **GPU:** NVIDIA RTX 3xxx (Инструкции sm85+) с поддержкой CUDA 12.8 (6+ GB VRAM)
- **Git:** [Скачать Git для Windows](https://git-scm.com/download/win)

## 🧩 Структура

```
ComfyUI_TRELLIS2_Portable/
├── Trellis2_portable.ps1   # Главный установщик
├── run_nvidia_gpu.bat      # Скрипт запуска
├── settings.yaml           # Конфиг для установки
├── uv.exe                  # uv package manager (автозагрузка)
├── comfy_env/              # Python-окружение (uv venv)
└── ComfyUI/                # Программа и кастомные ноды
```

## 📝 Лицензия

Проект распространяется под лицензией **Apache 2.0**.
