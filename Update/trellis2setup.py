# ---------------------------------------------------------
# \Update\trellis2setup.py
# Version: 1.0.0
# Author:  Soror L.'.L.'.
# Updated: 2026-04-24
#
# Patchnote v1.0.0:
#   [+] Initial release - Trellis2 GGUF installer for Conda environment
#   [+] Automatic model download (DINOv3 + Trellis2 GGUF)
#   [+] Wheel installation (cumesh, nvdiffrast, flex_gemm, o_voxel)
#   [+] Git clone of ComfyUI-Trellis2-GGUF custom node
# ---------------------------------------------------------

import os
import sys
import subprocess
import shutil
import urllib.request
import re
import socket
from tqdm import tqdm


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


VERSION = "1.0.0"
NODE_NAME = "Trellis2 GGUF"
TITLE = f"{NODE_NAME} Installer v{VERSION}"


SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
os.chdir(SCRIPT_DIR)


DIR_LVL = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))
PYTHON_EXE = os.path.join(DIR_LVL, "comfy_env", "python.exe")
COMFYUI_DIR = os.path.join(DIR_LVL, "ComfyUI")

PIP_ARGS = ["--no-cache-dir", "--no-warn-script-location", "--timeout=1000", "--retries=20", "--use-pep517"]


BASE_URL_DINOV3 = "https://huggingface.co/PIA-SPACE-LAB/dinov3-vitl-pretrain-lvd1689m/resolve/main"
FOLDER_DINOV3 = os.path.join(COMFYUI_DIR, "models", "facebook", "dinov3-vitl16-pretrain-lvd1689m")

DINOV3_MANIFEST = [
    ("model.safetensors", "DINOv3 Model"),
    ("config.json", "DINOv3 Config"),
    ("preprocessor_config.json", "DINOv3 Pre-config")
]


BASE_URL_TRELLIS = "https://huggingface.co/Aero-Ex/Trellis2-GGUF/resolve/main"
FOLDER_TRELLIS = os.path.join(COMFYUI_DIR, "models", "Trellis2")

TRELLIS2_MANIFEST = [
    ("pipeline.json", "Pipeline Config"),
    ("refiner/ss_flow_img_dit_1_3B_64_bf16.json", "Sparse Structure Config"),
    ("refiner/ss_flow_img_dit_1_3B_64_bf16_Q4_K_M.gguf", "Sparse Structure Model"),
    ("shape/slat_flow_img2shape_dit_1_3B_512_bf16.json", "Shape 512 Config"),
    ("shape/slat_flow_img2shape_dit_1_3B_512_bf16_Q4_K_M.gguf", "Shape 512 Model"),
    ("shape/slat_flow_img2shape_dit_1_3B_1024_bf16.json", "Shape 1024 Config"),
    ("shape/slat_flow_img2shape_dit_1_3B_1024_bf16_Q4_K_M.gguf", "Shape 1024 Model"),
    ("texture/slat_flow_imgshape2tex_dit_1_3B_512_bf16.json", "Texture 512 Config"),
    ("texture/slat_flow_imgshape2tex_dit_1_3B_512_bf16_Q4_K_M.gguf", "Texture 512 Model"),
    ("texture/slat_flow_imgshape2tex_dit_1_3B_1024_bf16.json", "Texture 1024 Config"),
    ("texture/slat_flow_imgshape2tex_dit_1_3B_1024_bf16_Q4_K_M.gguf", "Texture 1024 Model"),
    ("decoders/Stage1/ss_dec_conv3d_16l8_fp16.json", "SS Decoder Config"),
    ("decoders/Stage1/ss_dec_conv3d_16l8_fp16.safetensors", "SS Decoder Model"),
    ("decoders/Stage2/shape_dec_next_dc_f16c32_fp16.json", "Shape Decoder Config"),
    ("decoders/Stage2/shape_dec_next_dc_f16c32_fp16.safetensors", "Shape Decoder Model"),
    ("decoders/Stage2/tex_dec_next_dc_f16c32_fp16.json", "Texture Decoder Config"),
    ("decoders/Stage2/tex_dec_next_dc_f16c32_fp16.safetensors", "Texture Decoder Model"),
    ("encoders/shape_enc_next_dc_f16c32_fp16.json", "Shape Encoder Config"),
    ("encoders/shape_enc_next_dc_f16c32_fp16.safetensors", "Shape Encoder Model"),
]


WHEELS_LIST = [
    ("cumesh", "https://github.com/visualbruno/CuMesh/releases/download/v1.0/cumesh-1.0-cp312-cp312-win_amd64.whl"),
    ("nvdiffrast", "https://github.com/NVlabs/nvdiffrast/releases/download/v0.4.0/nvdiffrast-0.4.0-cp312-cp312-win_amd64.whl"),
    ("nvdiffrec_render", "https://github.com/NVlabs/nvdiffrec/releases/download/v0.0.0/nvdiffrec_render-0.0.0-cp312-cp312-win_amd64.whl"),
    ("flex_gemm", "https://github.com/flexflow/FlexGemm/releases/download/v0.0.1/flex_gemm-0.0.1-cp312-cp312-win_amd64.whl"),
    ("o_voxel", "https://github.com/visualbruno/OVoxel/releases/download/v0.0.1/o_voxel-0.0.1-cp312-cp312-win_amd64.whl"),
]


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


def run_command(cmd, check=True):
    result = subprocess.run(cmd, capture_output=True, text=True)
    if check and result.returncode != 0:
        write_status(f"Error executing command: {' '.join(cmd)}", "ERROR")
        print(result.stderr)
        sys.exit(1)
    return result


def erase_folder(path):
    if os.path.exists(path):
        shutil.rmtree(path)


def download_file(url, dest_path):
    tmp_path = dest_path + ".tmp"
    try:
        with urllib.request.urlopen(url) as response:
            file_size = int(response.info().get('Content-Length', -1))
            with tqdm(total=file_size, unit='B', unit_scale=True, unit_divisor=1024,
                      desc=f"{Colors.CYAN}Downloading{Colors.RESET} {os.path.basename(dest_path)}",
                      ascii=True, miniters=1) as bar:
                with open(tmp_path, 'wb') as f:
                    while True:
                        chunk = response.read(8192)
                        if not chunk:
                            break
                        f.write(chunk)
                        bar.update(len(chunk))
        os.replace(tmp_path, dest_path)
    except Exception as e:
        if os.path.exists(tmp_path):
            os.remove(tmp_path)
        raise Exception(f"{e}")


def process_downloads(manifest, base_url, target_folder, force_delete=None):
    if force_delete is None:
        force_delete = []
    
    failed = []
    os.makedirs(target_folder, exist_ok=True)
    
    for fname in force_delete:
        full_path = os.path.join(target_folder, fname)
        if os.path.exists(full_path):
            os.remove(full_path)
    
    for i, (filename, label) in enumerate(manifest, 1):
        dest_path = os.path.join(target_folder, filename)
        url = f"{base_url}/{filename}"
        
        if os.path.exists(dest_path):
            size_mb = os.path.getsize(dest_path) / (1024 * 1024)
            status = f"{Colors.GREEN}already exists{Colors.RESET} ({size_mb:.0f} MB)" if size_mb > 1 else f"{Colors.GREEN}already exists{Colors.RESET}"
            print(f"[{i:2d}/{len(manifest)}] {label:25s}  {status}")
            continue
        
        print(f"[{i:2d}/{len(manifest)}] {label:25s}  {Colors.YELLOW}downloading...{Colors.RESET}")
        try:
            download_file(url, dest_path)
            print(f"[{i:2d}/{len(manifest)}] {label:25s}  {Colors.GREEN}done{Colors.RESET}")
        except Exception as e:
            write_status(f"Failed {label}: {e}", "ERROR")
            failed.append(filename)
    
    return failed


# === 1. Check Environment ===
def step_check_environment():
    write_step("Checking Python Environment (Conda)", 1, 7)
    
    if not os.path.exists(PYTHON_EXE):
        write_status(f"Python not found at {PYTHON_EXE}", "ERROR")
        write_status("Make sure Trellis2 is installed in the correct Conda environment", "WARN")
        input("Press Enter to exit...")
        sys.exit(1)
    
    write_status(f"Python found: {PYTHON_EXE}", "SUCCESS")


# === 2. Check ComfyUI Directory ===
def step_check_comfyui():
    write_step("Checking ComfyUI Directory Structure", 2, 7)
    
    if not os.path.exists(COMFYUI_DIR):
        write_status(f"ComfyUI directory not found: {COMFYUI_DIR}", "ERROR")
        input("Press Enter to exit...")
        sys.exit(1)
    
    write_status(f"ComfyUI found: {COMFYUI_DIR}", "SUCCESS")


# === 3. Check ComfyUI Status ===
def step_check_comfyui_status():
    write_step("Checking ComfyUI Status (Port 8188)", 3, 7)
    
    try:
        if socket.socket(socket.AF_INET, socket.SOCK_STREAM).connect_ex(('127.0.0.1', 8188)) == 0:
            write_status("ComfyUI is already running on port 8188. Please close it first.", "WARN")
            input("Press Enter to exit...")
            sys.exit(1)
        else:
            write_status("ComfyUI is not running. Good to proceed.", "SUCCESS")
    except:
        write_status("Could not verify ComfyUI status. Proceeding anyway...", "WARN")


# === 4. Install Custom Node ===
def step_install_custom_node():
    write_step("Cloning and Installing ComfyUI-Trellis2-GGUF Node", 4, 7)
    
    custom_nodes = os.path.join(COMFYUI_DIR, "custom_nodes")
    trellis_node = os.path.join(custom_nodes, "ComfyUI-Trellis2-GGUF")
    
    if os.path.exists(trellis_node):
        write_status("Removing existing Trellis2 node...", "WARN")
        shutil.rmtree(trellis_node)
    
    write_status("Cloning Trellis2 GGUF repository...", "INFO")
    run_command(["git", "clone", "https://github.com/Aero-Ex/ComfyUI-Trellis2-GGUF", trellis_node])
    
    req_path = os.path.join(trellis_node, "requirements.txt")
    if os.path.exists(req_path):
        write_status("Installing Python dependencies from requirements.txt...", "INFO")
        run_command([PYTHON_EXE, "-m", "pip", "install", "-r", req_path, "--no-deps"] + PIP_ARGS)
    
    write_status("Upgrading huggingface_hub...", "INFO")
    run_command([PYTHON_EXE, "-m", "pip", "install", "--upgrade", "huggingface_hub", "--no-deps"] + PIP_ARGS)
    
    write_status("Custom node installed successfully", "SUCCESS")


# === 5. Install Wheels ===
def step_install_wheels():
    write_step("Installing Pre-compiled Wheels (cumesh, nvdiffrast, etc.)", 5, 7)
    
    temp_wheels_dir = os.path.join(DIR_LVL, "temp_wheels")
    os.makedirs(temp_wheels_dir, exist_ok=True)
    
    site_packages = os.path.join(DIR_LVL, "comfy_env", "Lib", "site-packages")
    
    old_packages = ["o_voxel", "cumesh", "nvdiffrast", "nvdiffrec_render", "flex_gemm"]
    for pkg in old_packages:
        for item in os.listdir(site_packages):
            if item.startswith(pkg):
                pkg_path = os.path.join(site_packages, item)
                if os.path.isdir(pkg_path):
                    erase_folder(pkg_path)
                elif os.path.isfile(pkg_path):
                    os.remove(pkg_path)
    
    for wheel_name, wheel_url in WHEELS_LIST:
        wheel_filename = wheel_url.split("/")[-1]
        wheel_path = os.path.join(temp_wheels_dir, wheel_filename)
        
        if os.path.exists(wheel_path):
            write_status(f"{wheel_name} wheel found in cache", "INFO")
        else:
            write_status(f"Downloading {wheel_name}...", "INFO")
            try:
                urllib.request.urlretrieve(wheel_url, wheel_path)
                write_status(f"{wheel_name} downloaded", "SUCCESS")
            except Exception as e:
                write_status(f"Failed to download {wheel_name}: {e}", "WARN")
                continue
        
        write_status(f"Installing {wheel_name}...", "INFO")
        run_command([PYTHON_EXE, "-m", "pip", "install", wheel_path, "--no-deps"])
    
    write_status("All wheels installed successfully", "SUCCESS")


# === 6. Download Models ===
def step_download_models():
    write_step("Downloading AI Models (DINOv3 + Trellis2 GGUF)", 6, 7)
    
    write_status("--- DINOv3 Model ---", "INFO")
    failed_dinov3 = process_downloads(DINOV3_MANIFEST, BASE_URL_DINOV3, FOLDER_DINOV3, force_delete=["model.safetensors"])
    
    print("")
    write_status("--- Trellis2 GGUF Models (Q4_K_M) ---", "INFO")
    failed_trellis = process_downloads(TRELLIS2_MANIFEST, BASE_URL_TRELLIS, FOLDER_TRELLIS)
    
    print("")
    print("=" * 50)
    if not failed_trellis and not failed_dinov3:
        write_status("All models downloaded successfully", "SUCCESS")
    else:
        if failed_dinov3:
            write_status(f"DINOv3 downloads failed: {failed_dinov3}", "WARN")
        if failed_trellis:
            write_status(f"Trellis2 downloads failed: {failed_trellis}", "WARN")
    print("=" * 50)
    print("")


# === 7. Apply Patches ===
def step_apply_patches():
    write_step("Applying Required Patches", 7, 7)
    
    site_packages = os.path.join(DIR_LVL, "comfy_env", "Lib", "site-packages")
    remesh_path = os.path.join(site_packages, "cumesh", "remeshing.py")
    
    if os.path.exists(remesh_path):
        backup_path = remesh_path + ".bak"
        if not os.path.exists(backup_path):
            shutil.copy(remesh_path, backup_path)
            write_status("Created backup of remeshing.py", "INFO")
        
        try:
            urllib.request.urlretrieve(
                "https://raw.githubusercontent.com/visualbruno/CuMesh/main/cumesh/remeshing.py",
                remesh_path
            )
            write_status("Patched remeshing.py successfully", "SUCCESS")
        except Exception as e:
            write_status(f"Failed to patch remeshing.py: {e}", "WARN")
    
    run_command([PYTHON_EXE, "-m", "pip", "install", "--upgrade", "pooch", "--no-deps"] + PIP_ARGS)
    
    result = subprocess.run([PYTHON_EXE, "-c", "import numpy, sys; sys.exit(0 if numpy.__version__ == '1.26.4' else 1)"])
    if result.returncode != 0:
        write_status("Restoring numpy 1.26.4 for compatibility...", "INFO")
        run_command([PYTHON_EXE, "-m", "pip", "install", "--force-reinstall", "numpy==1.26.4", "--no-deps"] + PIP_ARGS)
    
    write_status("All patches applied successfully", "SUCCESS")


# === Main ===
def main():
    os.system(f"title {TITLE}")
    os.system("cls" if os.name == "nt" else "clear")
    
    print("")
    print(f"{Colors.GREEN}==========================================={Colors.RESET}")
    print(f"{Colors.YELLOW}  Trellis2 GGUF Installer v{VERSION}{Colors.RESET}")
    print(f"{Colors.GREEN}  ComfyUI Conda Environment Edition{Colors.RESET}")
    print(f"{Colors.GREEN}==========================================={Colors.RESET}")
    print("")
    
    step_check_environment()
    step_check_comfyui()
    step_check_comfyui_status()
    step_install_custom_node()
    step_install_wheels()
    step_download_models()
    step_apply_patches()
    
    print("")
    print(f"{Colors.GREEN}==========================================={Colors.RESET}")
    write_status(f"{NODE_NAME} Installation Complete", "SUCCESS")
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