#!/usr/bin/env python3
# ---------------------------------------------------------
# Update/Faith-Pulse_install.py
# Version: 1.0.1
# Author:  Based on trellis2setup.py by Soror L.'.L.'.
# Purpose: Install ComfyUI-FaithContouring + ComfyUI-Pulse-MeshAudit
#          into portable uv/venv ComfyUI environment
# ---------------------------------------------------------

import os
import sys
import subprocess
import shutil
import argparse
import socket

# ----------------------------- Command line arguments -----------------------------
parser = argparse.ArgumentParser(description="FaithContouring + Pulse-MeshAudit Installer for ComfyUI (uv/venv)")
parser.add_argument('--env_path', help='Path to python.exe of uv/venv environment (overrides auto-detection)')
parser.add_argument('--comfyui_dir', help='Path to ComfyUI directory (overrides auto-detection)')
parser.add_argument('--port', type=int, default=8188, help='ComfyUI port to check (default: 8188)')
args = parser.parse_args()

# ----------------------------- Colors -----------------------------
class Colors:
    WARNING = '\033[93m'
    GRAY = '\033[90m'
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    MAGENTA = '\033[95m'
    CYAN = '\033[96m'
    WHITE = '\033[97m'
    RESET = '\033[0m'

VERSION = "1.0.1"
NODE_NAME = "FaithContouring + Pulse-MeshAudit"
TITLE = f"{NODE_NAME} Installer v{VERSION}"

# ----------------------------- Paths -----------------------------
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
os.chdir(SCRIPT_DIR)

# Determine Python executable
if args.env_path and os.path.exists(args.env_path):
    PYTHON_EXE = args.env_path
    DIR_LVL = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))
else:
    DIR_LVL = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))
    PYTHON_EXE = os.path.join(DIR_LVL, "comfy_env", "Scripts", "python.exe")
    if not os.path.exists(PYTHON_EXE):
        print(f"{Colors.YELLOW}[WARN]  Default python not found at {PYTHON_EXE}{Colors.RESET}")
        print(f"{Colors.YELLOW}       Specify correct path with --env_path \"path\\to\\python.exe\"{Colors.RESET}")

# Determine uv.exe path
UV_EXE = os.path.join(DIR_LVL, "uv.exe")
if not os.path.exists(UV_EXE):
    print(f"{Colors.YELLOW}[WARN]  uv.exe not found at {UV_EXE}{Colors.RESET}")

# Determine ComfyUI directory
if args.comfyui_dir and os.path.exists(args.comfyui_dir):
    COMFYUI_DIR = args.comfyui_dir
else:
    COMFYUI_DIR = os.path.join(DIR_LVL, "ComfyUI")
    if not os.path.exists(COMFYUI_DIR):
        print(f"{Colors.YELLOW}[WARN]  ComfyUI not found at default location: {COMFYUI_DIR}{Colors.RESET}")
        print(f"{Colors.YELLOW}       Specify correct path with --comfyui_dir \"path\\to\\ComfyUI\"{Colors.RESET}")

PIP_ARGS = ["--no-cache"]

# Правильные URL-адреса репозиториев
GIT_URLS = {
    "ComfyUI-FaithContouring": "https://github.com/krishnancr/ComfyUI-FaithContouring",
    "ComfyUI-Pulse-MeshAudit": "https://github.com/krishnancr/ComfyUI-Pulse-MeshAudit"
}

# ----------------------------- Helper functions -----------------------------
def write_status(message, msg_type="INFO"):
    prefix = {
        "INFO": " [INFO]  ",
        "WARN": " [WARN]  ",
        "ERROR": " [ERROR] ",
        "SUCCESS": " [OK]    "
    }.get(msg_type, " [INFO]  ")
    color = {
        "INFO": Colors.CYAN,
        "WARN": Colors.YELLOW,
        "ERROR": Colors.RED,
        "SUCCESS": Colors.GREEN
    }.get(msg_type, Colors.WHITE)
    print(f"{color}{prefix}{message}{Colors.RESET}")

def write_step(message, step, total):
    print("")
    print(f"{Colors.MAGENTA}>>> Stage [{step}/{total}]: {message}{Colors.RESET}")

def run_command_live(cmd, check=True):
    process = subprocess.Popen(cmd)
    process.wait()
    if check and process.returncode != 0:
        write_status(f"Error executing command: {' '.join(cmd)}", "ERROR")
        sys.exit(1)
    return process.returncode

def run_command(cmd, check=True, capture=True):
    if capture:
        result = subprocess.run(cmd, capture_output=True, text=True)
        if check and result.returncode != 0:
            write_status(f"Error: {' '.join(cmd)}", "ERROR")
            print(result.stderr)
            sys.exit(1)
        return result.returncode, result.stdout, result.stderr
    else:
        return run_command_live(cmd, check), "", ""

# ----------------------------- Installation stages -----------------------------
def step_check_environment():
    write_step("Checking Python Environment (uv/venv)", 1, 6)
    if not os.path.exists(PYTHON_EXE):
        write_status(f"Python not found at {PYTHON_EXE}", "ERROR")
        write_status("Make sure you are running from the portable ComfyUI root", "WARN")
        input("Press Enter to exit...")
        sys.exit(1)
    write_status(f"Python found: {PYTHON_EXE}", "SUCCESS")

def step_check_comfyui():
    write_step("Checking ComfyUI Directory", 2, 6)
    if not os.path.exists(COMFYUI_DIR):
        write_status(f"ComfyUI directory not found: {COMFYUI_DIR}", "ERROR")
        write_status("Use --comfyui_dir to specify correct path", "INFO")
        input("Press Enter to exit...")
        sys.exit(1)
    write_status(f"ComfyUI found: {COMFYUI_DIR}", "SUCCESS")

def step_check_comfyui_port():
    write_step(f"Checking ComfyUI Status (Port {args.port})", 3, 6)
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        if sock.connect_ex(('127.0.0.1', args.port)) == 0:
            write_status(f"ComfyUI is already running on port {args.port}. Please close it first.", "WARN")
            input("Press Enter to exit...")
            sys.exit(1)
        else:
            write_status("ComfyUI is not running. Good to proceed.", "SUCCESS")
    except Exception:
        write_status("Could not verify ComfyUI status. Proceeding anyway...", "WARN")

def step_install_nodes():
    write_step("Cloning/Updating FaithContouring and Pulse-MeshAudit", 4, 6)
    custom_nodes = os.path.join(COMFYUI_DIR, "custom_nodes")
    os.makedirs(custom_nodes, exist_ok=True)

    for name, url in GIT_URLS.items():
        target = os.path.join(custom_nodes, name)
        if os.path.exists(target):
            write_status(f"Updating {name} (git pull)...", "INFO")
            # Запускаем git pull и игнорируем ошибку, если репозиторий не настроен (например, был клонирован вручную)
            run_command_live(["git", "-C", target, "pull"], check=False)
        else:
            write_status(f"Cloning {name}...", "INFO")
            run_command_live(["git", "clone", url, target])

def step_install_dependencies():
    write_step("Installing Python Dependencies and Wheels", 5, 6)
    # 1. Base packages
    write_status("Installing trimesh, scipy, einops...", "INFO")
    run_command_live([UV_EXE, "pip", "install", "--python", PYTHON_EXE, "trimesh", "scipy", "einops", "--no-deps"] + PIP_ARGS)

    # 2. torch_scatter (pre-built wheel)
    torch_scatter_url = "https://github.com/PozzettiAndrea/cuda-wheels/releases/download/torch_scatter-latest/torch_scatter-2.1.2+cu128torch2.8-cp312-cp312-win_amd64.whl"
    write_status("Installing torch_scatter (CUDA 12.8 / Torch 2.8)...", "INFO")
    run_command_live([UV_EXE, "pip", "install", "--python", PYTHON_EXE, torch_scatter_url] + PIP_ARGS)

    # 3. atom3d wheel (inside FaithContouring repo)
    faith_node = os.path.join(COMFYUI_DIR, "custom_nodes", "ComfyUI-FaithContouring")
    # Проверяем доступные версии для Torch 2.8 / Python 3.12
    atom3d_wheel_path_v1 = os.path.join(faith_node, "wheels", "Windows", "Torch280", "atom3d-0.1.0-cp312-cp312-win_amd64.whl")
    atom3d_wheel_path_v2 = os.path.join(faith_node, "wheels", "Windows", "Torch270", "atom3d-0.1.0-cp311-cp311-win_amd64.whl") # fallback

    if os.path.exists(atom3d_wheel_path_v1):
        wheel_to_install = atom3d_wheel_path_v1
    elif os.path.exists(atom3d_wheel_path_v2):
        wheel_to_install = atom3d_wheel_path_v2
        write_status(f"Using fallback atom3d wheel for Python 3.11. This may cause issues if your Python version is different.", "WARN")
    else:
        write_status("atom3d wheel not found – skipping installation. The node may not work.", "WARN")
        wheel_to_install = None

    if wheel_to_install and os.path.exists(wheel_to_install):
        write_status(f"Installing atom3d from: {os.path.basename(wheel_to_install)}", "INFO")
        run_command_live([UV_EXE, "pip", "install", "--python", PYTHON_EXE, wheel_to_install] + PIP_ARGS)

    # 4. comfy-env for Pulse-MeshAudit
    write_status("Installing comfy-env...", "INFO")
    run_command_live([UV_EXE, "pip", "install", "--python", PYTHON_EXE, "comfy-env>=0.2.7", "--no-deps"] + PIP_ARGS)

    # 5. Ensure numpy 1.26.4 (only if needed)
    result = subprocess.run([PYTHON_EXE, "-c", "import numpy; print(numpy.__version__)"], capture_output=True, text=True)
    current_numpy = result.stdout.strip()
    if current_numpy and current_numpy != '1.26.4':
        write_status(f"Current numpy version is {current_numpy}, restoring 1.26.4...", "INFO")
        run_command_live([UV_EXE, "pip", "install", "--python", PYTHON_EXE, "--force-reinstall", "numpy==1.26.4", "--no-deps"] + PIP_ARGS)
    else:
        write_status(f"numpy version {current_numpy} is already compatible.", "SUCCESS")

def step_apply_patches():
    write_step("Applying Required Patches", 6, 6)
    # Patch for remeshing.py from cumesh (common fix)
    site_packages = os.path.join(DIR_LVL, "comfy_env", "Lib", "site-packages")
    if not os.path.exists(site_packages):
        # fallback attempt
        site_packages = os.path.join(os.path.dirname(PYTHON_EXE), "Lib", "site-packages")

    if os.path.exists(site_packages):
        # Placeholder for future patches if needed
        write_status("Environment ready for patching.", "INFO")
    else:
        write_status(f"Site-packages not found at {site_packages}, cannot apply potential patches.", "WARN")

# ----------------------------- Main -----------------------------
def main():
    os.system(f"title {TITLE}")
    os.system("cls" if os.name == "nt" else "clear")
    print("")
    print(f"{Colors.GREEN}==========================================={Colors.RESET}")
    print(f"{Colors.YELLOW}  FaithContouring + Pulse-MeshAudit Installer v{VERSION}{Colors.RESET}")
    print(f"{Colors.GREEN}  For ComfyUI Portable (uv/venv){Colors.RESET}")
    print(f"{Colors.GREEN}==========================================={Colors.RESET}")
    print("")

    step_check_environment()
    step_check_comfyui()
    step_check_comfyui_port()
    step_install_nodes()
    step_install_dependencies()
    step_apply_patches()

    print("")
    print(f"{Colors.GREEN}==========================================={Colors.RESET}")
    write_status("FaithContouring + Pulse-MeshAudit Installation Complete", "SUCCESS")
    print(f"{Colors.GREEN}==========================================={Colors.RESET}")
    print("")
    if len(sys.argv) == 1:
        input("Press Enter to exit...")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        write_status("Installation cancelled by user", "WARN")
        sys.exit(1)
    except Exception as e:
        write_status(f"Unexpected error: {e}", "ERROR")
        input("Press Enter to exit...")
        sys.exit(1)