#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Environment Scanner for ComfyUI (Trellis2 portable build)
Displays information about Python, ComfyUI, key packages, and system resources.
"""

import sys
import os
import platform
import importlib.metadata
import importlib.util
import subprocess
import json
from datetime import datetime

# ----------------------------------------------------------------------
# Helper functions
# ----------------------------------------------------------------------
def get_package_version(package_name):
    """Safely get version of an installed package."""
    try:
        return importlib.metadata.version(package_name)
    except importlib.metadata.PackageNotFoundError:
        return None

def module_available(module_name):
    """Check if a Python module can be imported."""
    return importlib.util.find_spec(module_name) is not None

def get_comfyui_version():
    """Try to get ComfyUI version from comfyui_version module."""
    try:
        # Add ComfyUI folder to path if needed
        comfyui_path = os.path.join(os.path.dirname(__file__), "ComfyUI")
        if comfyui_path not in sys.path:
            sys.path.insert(0, comfyui_path)
        import comfyui_version
        return comfyui_version.__version__
    except ImportError:
        return "Not available (ComfyUI not found or not importable)"

def get_gpu_info():
    """Get basic GPU info using nvidia-smi if available."""
    gpus = []
    try:
        if sys.platform == "win32":
            nvidia_smi = subprocess.run(
                ["nvidia-smi", "--query-gpu=name,memory.total", "--format=csv,noheader"],
                capture_output=True, text=True, encoding='utf-8', errors='ignore'
            )
            if nvidia_smi.returncode == 0:
                for line in nvidia_smi.stdout.strip().split('\n'):
                    if line:
                        name, mem = line.split(', ')
                        gpus.append({"name": name.strip(), "memory_total": mem.strip()})
        else:
            # Linux / macOS
            nvidia_smi = subprocess.run(
                ["nvidia-smi", "--query-gpu=name,memory.total", "--format=csv,noheader"],
                capture_output=True, text=True
            )
            if nvidia_smi.returncode == 0:
                for line in nvidia_smi.stdout.strip().split('\n'):
                    if line:
                        name, mem = line.split(', ')
                        gpus.append({"name": name.strip(), "memory_total": mem.strip()})
    except FileNotFoundError:
        pass
    return gpus

def get_folders():
    """Get ComfyUI folder paths if available."""
    folders = {}
    try:
        comfyui_path = os.path.join(os.path.dirname(__file__), "ComfyUI")
        if comfyui_path not in sys.path:
            sys.path.insert(0, comfyui_path)
        import folder_paths
        folders["output_directory"] = folder_paths.get_output_directory()
        folders["input_directory"] = folder_paths.get_input_directory()
        folders["temp_directory"] = folder_paths.get_temp_directory()
        folders["user_directory"] = folder_paths.get_user_directory()
        folders["model_folders"] = folder_paths.get_folder_paths("models") if hasattr(folder_paths, "get_folder_paths") else []
        folders["custom_nodes_folders"] = folder_paths.get_folder_paths("custom_nodes") if hasattr(folder_paths, "get_folder_paths") else []
    except Exception as e:
        folders["error"] = str(e)
    return folders

# ----------------------------------------------------------------------
# Main collection
# ----------------------------------------------------------------------
def collect_info():
    info = {
        "timestamp": datetime.now().isoformat(),
        "system": {
            "platform": platform.platform(),
            "system": platform.system(),
            "release": platform.release(),
            "machine": platform.machine(),
            "processor": platform.processor(),
            "hostname": platform.node(),
        },
        "python": {
            "version": sys.version,
            "executable": sys.executable,
            "path": sys.path,
        },
        "comfyui": {
            "version": get_comfyui_version(),
            "path": os.path.abspath("ComfyUI") if os.path.exists("ComfyUI") else None,
        },
        "packages": {
            "comfy-aimdo": get_package_version("comfy-aimdo"),
            "comfy-kitchen": get_package_version("comfy-kitchen"),
            "comfyui-frontend-package": get_package_version("comfyui-frontend-package"),
            "torch": get_package_version("torch"),
            "torchvision": get_package_version("torchvision"),
            "torchaudio": get_package_version("torchaudio"),
            "pygit2": get_package_version("pygit2"),
            "xformers": get_package_version("xformers"),
        },
        "gpu": get_gpu_info(),
    }

    # Try to get folder paths (optional, may fail if ComfyUI not fully importable)
    if module_available("folder_paths"):
        try:
            info["folders"] = get_folders()
        except Exception as e:
            info["folders_error"] = str(e)

    return info

# ----------------------------------------------------------------------
# Output
# ----------------------------------------------------------------------
if __name__ == "__main__":
    data = collect_info()
    
    # Print as nicely formatted JSON
    print(json.dumps(data, indent=2, ensure_ascii=False))
    
    # Also print a human-readable summary
    print("\n" + "="*60)
    print("ENVIRONMENT SUMMARY")
    print("="*60)
    print(f"Python       : {data['python']['version'].split()[0]}")
    print(f"ComfyUI      : {data['comfyui']['version']}")
    print(f"comfy-aimdo  : {data['packages']['comfy-aimdo'] or 'not installed'}")
    print(f"comfy-kitchen: {data['packages']['comfy-kitchen'] or 'not installed'}")
    print(f"torch        : {data['packages']['torch'] or 'not installed'}")
    print(f"GPU(s)       : {', '.join([g['name'] for g in data['gpu']]) if data['gpu'] else 'No NVIDIA GPU detected'}")
    print(f"OS           : {data['system']['platform']}")
    print("="*60)