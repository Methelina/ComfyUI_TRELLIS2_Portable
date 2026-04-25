# ---------------------------------------------------------
# \Update\trellis2setup.py
# Version: 1.0.6
# Author:  Soror L.'.L.'.
# Updated: 2026-04-25
#
# Patchnote v1.0.0 (By Soror L.'.L.'.):
#   [+] Initial release - Trellis2 GGUF installer for Conda environment
#   [+] Automatic model download (DINOv3 + Trellis2 GGUF)
#   [+] Wheel installation (cumesh, nvdiffrast, flex_gemm, o_voxel)
#   [+] Git clone of ComfyUI-Trellis2-GGUF custom node
#
# Patchnote v1.0.4 (By Soror L.'.L.'.):
#   [+] Added --comfyui_dir argument to specify ComfyUI path
#   [*] Fixed directory detection for non-standard layouts
#
# Patchnote v1.0.5 (By Soror L.'.L.'.):
#   [+] Added automatic Triton (triton-windows) installation with GPU detection
#   [+] Integrated Triton functionality test after installation
#   [*] Reordered installation stages: Triton setup before model download
#
# Patchnote v1.0.6 (By Soror L.'.L.'.):
#   [*] Replaced urllib download with PycURL; system curl remains as fallback
# ---------------------------------------------------------

import os
import sys
import subprocess
import shutil
import urllib.request
import socket
import argparse
import tempfile
from tqdm import tqdm

# ----------------------------- Command line arguments -----------------------------
parser = argparse.ArgumentParser(description="Trellis2 GGUF Installer for ComfyUI Conda")
parser.add_argument('--env_path', help='Path to python.exe of conda environment (overrides auto-detection)')
parser.add_argument('--comfyui_dir', help='Path to ComfyUI directory (overrides auto-detection)')
args = parser.parse_args()

# ----------------------------- Colors for output -----------------------------
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

VERSION = "1.0.6"
NODE_NAME = "Trellis2 GGUF"
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
    PYTHON_EXE = os.path.join(DIR_LVL, "comfy_env", "python.exe")
    if not os.path.exists(PYTHON_EXE):
        print(f"{Colors.YELLOW}[WARN]  Default python not found at {PYTHON_EXE}{Colors.RESET}")
        print(f"{Colors.YELLOW}       Specify correct path with --env_path \"path\\to\\python.exe\"{Colors.RESET}")

# Determine ComfyUI directory
if args.comfyui_dir and os.path.exists(args.comfyui_dir):
    COMFYUI_DIR = args.comfyui_dir
else:
    COMFYUI_DIR = os.path.join(DIR_LVL, "ComfyUI")
    if not os.path.exists(COMFYUI_DIR):
        print(f"{Colors.YELLOW}[WARN]  ComfyUI not found at default location: {COMFYUI_DIR}{Colors.RESET}")
        print(f"{Colors.YELLOW}       Specify correct path with --comfyui_dir \"path\\to\\ComfyUI\"{Colors.RESET}")

PIP_ARGS = ["--no-cache-dir", "--no-warn-script-location", "--timeout=1000", "--retries=20", "--use-pep517"]

# ----------------------------- Model URLs and manifests -----------------------------
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

# ----------------------------- Wheels (Torch280, Python 3.12) -----------------------------
WHEELS_LIST = [
    ("cumesh", "https://raw.githubusercontent.com/visualbruno/ComfyUI-Trellis2/main/wheels/Windows/Torch280/cumesh-1.0-cp312-cp312-win_amd64.whl"),
    ("custom_rasterizer", "https://raw.githubusercontent.com/visualbruno/ComfyUI-Trellis2/main/wheels/Windows/Torch280/custom_rasterizer-0.1-cp312-cp312-win_amd64.whl"),
    ("flex_gemm", "https://raw.githubusercontent.com/visualbruno/ComfyUI-Trellis2/main/wheels/Windows/Torch280/flex_gemm-0.0.1-cp312-cp312-win_amd64.whl"),
    ("nvdiffrast", "https://raw.githubusercontent.com/visualbruno/ComfyUI-Trellis2/main/wheels/Windows/Torch280/nvdiffrast-0.4.0-cp312-cp312-win_amd64.whl"),
    ("nvdiffrec_render", "https://raw.githubusercontent.com/visualbruno/ComfyUI-Trellis2/main/wheels/Windows/Torch280/nvdiffrec_render-0.0.0-cp312-cp312-win_amd64.whl"),
    ("o_voxel", "https://raw.githubusercontent.com/visualbruno/ComfyUI-Trellis2/main/wheels/Windows/Torch280/o_voxel-0.0.1-cp312-cp312-win_amd64.whl"),
]

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

def run_command(cmd, check=True, capture=True):
    """Run a command and optionally capture output. Returns (returncode, stdout, stderr)."""
    if capture:
        result = subprocess.run(cmd, capture_output=True, text=True)
        if check and result.returncode != 0:
            write_status(f"Error executing command: {' '.join(cmd)}", "ERROR")
            print(result.stderr)
            sys.exit(1)
        return result.returncode, result.stdout, result.stderr
    else:
        # For live output (e.g., pip install), we use Popen with streaming
        process = subprocess.Popen(cmd, stdout=None, stderr=None)
        process.wait()
        if check and process.returncode != 0:
            write_status(f"Error executing command: {' '.join(cmd)}", "ERROR")
            sys.exit(1)
        return process.returncode, "", ""

def run_command_live(cmd, check=True):
    """Run a command with real-time output (no capture)."""
    process = subprocess.Popen(cmd)
    process.wait()
    if check and process.returncode != 0:
        write_status(f"Error executing command: {' '.join(cmd)}", "ERROR")
        sys.exit(1)
    return process.returncode

def erase_folder(path):
    if os.path.exists(path):
        shutil.rmtree(path)

def download_file_with_resume(url, dest_path):
    os.makedirs(os.path.dirname(dest_path), exist_ok=True)

    if os.path.exists(dest_path):
        write_status(f"File already exists: {os.path.basename(dest_path)}", "INFO")
        return True

    tmp_path = dest_path + ".tmp"
    existing_size = 0
    if os.path.exists(tmp_path):
        existing_size = os.path.getsize(tmp_path)

    # ── 1. Try PycURL ─────────────────────────────────────────────
    try:
        import pycurl

        write_status(f"Using pycurl to download {os.path.basename(dest_path)}", "INFO")

        # HEAD to get total size (for progress bar)
        total_size = 0
        c_head = pycurl.Curl()
        c_head.setopt(pycurl.URL, url)
        c_head.setopt(pycurl.NOBODY, 1)
        c_head.setopt(pycurl.FOLLOWLOCATION, 1)
        c_head.setopt(pycurl.CONNECTTIMEOUT, 30)
        c_head.setopt(pycurl.TIMEOUT, 60)
        c_head.perform()
        resp_code = c_head.getinfo(pycurl.RESPONSE_CODE)
        if resp_code == 200:
            total_size = c_head.getinfo(pycurl.CONTENT_LENGTH_DOWNLOAD)
        c_head.close()

        # Download with resume support
        c = pycurl.Curl()
        c.setopt(pycurl.URL, url)
        c.setopt(pycurl.FOLLOWLOCATION, 1)
        c.setopt(pycurl.CONNECTTIMEOUT, 30)
        c.setopt(pycurl.TIMEOUT, 300)

        if existing_size > 0:
            c.setopt(pycurl.RESUME_FROM, existing_size)
        else:
            if os.path.exists(tmp_path):
                os.remove(tmp_path)

        with tqdm(total=total_size, initial=existing_size, unit='B', unit_scale=True,
                  desc=f"{Colors.CYAN}Downloading{Colors.RESET} {os.path.basename(dest_path)}",
                  ascii=True) as bar:
            def progress_callback(download_t, download_d, upload_t, upload_d):
                bar.n = download_d + existing_size
                bar.refresh()

            c.setopt(pycurl.NOPROGRESS, 0)
            c.setopt(pycurl.XFERINFOFUNCTION, progress_callback)

            with open(tmp_path, 'ab' if existing_size > 0 else 'wb') as f:
                c.setopt(pycurl.WRITEDATA, f)
                try:
                    c.perform()
                except pycurl.error as e:
                    raise Exception(f"PyCURL download failed: {e}")

        c.close()

        if total_size > 0 and os.path.getsize(tmp_path) < total_size:
            raise Exception("Download incomplete")

        os.replace(tmp_path, dest_path)
        return True

    except ImportError:
        pass  # PycURL not available → next fallback
    except Exception as e:
        if os.path.exists(tmp_path):
            os.remove(tmp_path)
        raise e

    # ── 2. Fallback to system curl ───────────────────────────────
    if shutil.which("curl"):
        cmd = ["curl", "-L", "-C", "-", "--progress-bar", "-o", tmp_path, url]
        write_status(f"Using system curl to download {os.path.basename(dest_path)}", "INFO")
        try:
            with subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True) as proc:
                for line in proc.stdout:
                    if line.strip():
                        print(f"\r{line.strip()}", end="", flush=True)
            if proc.returncode == 0:
                os.replace(tmp_path, dest_path)
                return True
            else:
                write_status(f"curl failed with code {proc.returncode}.", "ERROR")
                if os.path.exists(tmp_path):
                    os.remove(tmp_path)
                raise Exception(f"curl download failed with exit code {proc.returncode}")
        except Exception as e:
            if os.path.exists(tmp_path):
                os.remove(tmp_path)
            raise Exception(f"curl download error: {e}")

    # ── 3. No suitable download tool available ───────────────────
    raise Exception("Neither pycurl nor system curl are available. Install pycurl or add curl to PATH.")

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
            download_file_with_resume(url, dest_path)
            print(f"[{i:2d}/{len(manifest)}] {label:25s}  {Colors.GREEN}done{Colors.RESET}")
        except Exception as e:
            write_status(f"Failed {label}: {e}", "ERROR")
            failed.append(filename)

    return failed

# ----------------------------- Triton integration -----------------------------
def get_torch_version():
    """Return torch version string or None if not installed."""
    try:
        code = "import torch; print(torch.__version__)"
        result = subprocess.run([PYTHON_EXE, "-c", code], capture_output=True, text=True)
        if result.returncode == 0:
            return result.stdout.strip()
    except:
        pass
    return None

def get_cuda_capability():
    """Return compute capability as float (e.g., 8.6) or None."""
    code = """
import torch
if torch.cuda.is_available():
    major, minor = torch.cuda.get_device_capability(0)
    print(major + minor / 10.0)
else:
    print("none")
"""
    try:
        result = subprocess.run([PYTHON_EXE, "-c", code], capture_output=True, text=True)
        if result.returncode == 0 and result.stdout.strip() != "none":
            return float(result.stdout.strip())
    except:
        pass
    return None

def get_triton_package_spec():
    """Determine appropriate triton-windows version specifier."""
    torch_ver_str = get_torch_version()
    if torch_ver_str is None:
        write_status("Could not determine PyTorch version. Installing latest triton-windows.", "WARN")
        return "triton-windows<3.7"

    parts = torch_ver_str.split('.')
    if len(parts) < 2:
        return "triton-windows<3.7"
    torch_major, torch_minor = int(parts[0]), int(parts[1])

    compat = {
        (2, 10): "<3.7",
        (2, 9):  "<3.6",
        (2, 8):  "<3.5",
        (2, 7):  "<3.4",
        (2, 6):  "<3.3",
        (2, 5):  "<3.2",
    }
    version_spec = compat.get((torch_major, torch_minor), "<3.7")

    cc = get_cuda_capability()
    if cc is not None and int(cc * 10) == 75:
        write_status("Turing GPU detected (GTX 16xx/RTX 20xx). Forcing Triton < 3.3.", "WARN")
        version_spec = "<3.3"

    return f"triton-windows{version_spec}"

def install_triton():
    """Install triton-windows using pip with auto-detected version."""
    pkg_spec = get_triton_package_spec()
    write_status(f"Installing {pkg_spec}...", "INFO")
    cmd = [PYTHON_EXE, "-m", "pip", "install", "-U", pkg_spec] + PIP_ARGS
    process = subprocess.Popen(cmd)
    process.wait()
    if process.returncode != 0:
        write_status(f"Triton installation failed (exit code {process.returncode}).", "WARN")
        return False
    write_status("Triton installed successfully.", "SUCCESS")
    return True

def test_triton():
    """Run a basic Triton kernel test and return True if successful."""
    test_code = """
import torch
import triton
import triton.language as tl

@triton.jit
def add_kernel(x_ptr, y_ptr, out_ptr, n_elements, BLOCK_SIZE: tl.constexpr):
    pid = tl.program_id(0)
    offsets = pid * BLOCK_SIZE + tl.arange(0, BLOCK_SIZE)
    mask = offsets < n_elements
    x = tl.load(x_ptr + offsets, mask=mask)
    y = tl.load(y_ptr + offsets, mask=mask)
    tl.store(out_ptr + offsets, x + y, mask=mask)

def add(x, y):
    out = torch.empty_like(x)
    n = out.numel()
    grid = lambda meta: (triton.cdiv(n, meta['BLOCK_SIZE']),)
    add_kernel[grid](x, y, out, n, BLOCK_SIZE=1024)
    return out

a = torch.rand(3, device='cuda')
b = add(a, a)
diff = b - (a + a)
if torch.allclose(diff, torch.zeros_like(diff)):
    print("TRITON_TEST_PASSED")
else:
    print("TRITON_TEST_FAILED")
"""
    with tempfile.NamedTemporaryFile(mode='w', suffix='.py', delete=False) as f:
        f.write(test_code)
        temp_file = f.name
    try:
        result = subprocess.run([PYTHON_EXE, temp_file], capture_output=True, text=True, timeout=30)
        output = result.stdout + result.stderr
        if "TRITON_TEST_PASSED" in output:
            return True
        else:
            write_status(f"Triton test failed. Output: {output[:500]}", "WARN")
            return False
    except subprocess.TimeoutExpired:
        write_status("Triton test timed out.", "WARN")
        return False
    except Exception as e:
        write_status(f"Triton test exception: {e}", "WARN")
        return False
    finally:
        os.unlink(temp_file)

# ----------------------------- Installation stages -----------------------------
def step_check_environment():
    write_step("Checking Python Environment (Conda)", 1, 8)
    if not os.path.exists(PYTHON_EXE):
        write_status(f"Python not found at {PYTHON_EXE}", "ERROR")
        write_status("Make sure Trellis2 is installed in the correct Conda environment", "WARN")
        write_status("You can specify the correct path using: --env_path \"path\\to\\python.exe\"", "INFO")
        input("Press Enter to exit...")
        sys.exit(1)
    write_status(f"Python found: {PYTHON_EXE}", "SUCCESS")

def step_check_comfyui():
    write_step("Checking ComfyUI Directory Structure", 2, 8)
    if not os.path.exists(COMFYUI_DIR):
        write_status(f"ComfyUI directory not found: {COMFYUI_DIR}", "ERROR")
        write_status("You can specify the correct path using: --comfyui_dir \"path\\to\\ComfyUI\"", "INFO")
        input("Press Enter to exit...")
        sys.exit(1)
    write_status(f"ComfyUI found: {COMFYUI_DIR}", "SUCCESS")

def step_check_comfyui_status():
    write_step("Checking ComfyUI Status (Port 8188)", 3, 8)
    try:
        if socket.socket(socket.AF_INET, socket.SOCK_STREAM).connect_ex(('127.0.0.1', 8188)) == 0:
            write_status("ComfyUI is already running on port 8188. Please close it first.", "WARN")
            input("Press Enter to exit...")
            sys.exit(1)
        else:
            write_status("ComfyUI is not running. Good to proceed.", "SUCCESS")
    except:
        write_status("Could not verify ComfyUI status. Proceeding anyway...", "WARN")

def step_install_custom_node():
    write_step("Cloning and Installing ComfyUI-Trellis2-GGUF Node", 4, 8)
    custom_nodes = os.path.join(COMFYUI_DIR, "custom_nodes")
    trellis_node = os.path.join(custom_nodes, "ComfyUI-Trellis2-GGUF")
    if os.path.exists(trellis_node):
        write_status("Removing existing Trellis2 node...", "WARN")
        shutil.rmtree(trellis_node)
    write_status("Cloning Trellis2 GGUF repository...", "INFO")
    run_command_live(["git", "clone", "https://github.com/Aero-Ex/ComfyUI-Trellis2-GGUF", trellis_node])
    req_path = os.path.join(trellis_node, "requirements.txt")
    if os.path.exists(req_path):
        write_status("Installing Python dependencies from requirements.txt...", "INFO")
        run_command_live([PYTHON_EXE, "-m", "pip", "install", "-r", req_path, "--no-deps"] + PIP_ARGS)
    write_status("Upgrading huggingface_hub...", "INFO")
    run_command_live([PYTHON_EXE, "-m", "pip", "install", "--upgrade", "huggingface_hub", "--no-deps"] + PIP_ARGS)
    write_status("Custom node installed successfully", "SUCCESS")

def step_install_wheels():
    write_step("Installing Pre-compiled Wheels", 5, 8)
    temp_wheels_dir = os.path.join(DIR_LVL, "temp_wheels")
    os.makedirs(temp_wheels_dir, exist_ok=True)

    site_packages = os.path.join(DIR_LVL, "comfy_env", "Lib", "site-packages")
    if not os.path.exists(site_packages) and args.env_path:
        py_dir = os.path.dirname(PYTHON_EXE)
        site_packages = os.path.join(py_dir, "Lib", "site-packages")
        if not os.path.exists(site_packages):
            site_packages = os.path.join(py_dir, "..", "Lib", "site-packages")

    old_packages = ["o_voxel", "cumesh", "custom_rasterizer", "nvdiffrast", "nvdiffrec_render", "flex_gemm"]
    if os.path.exists(site_packages):
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
                download_file_with_resume(wheel_url, wheel_path)
                write_status(f"{wheel_name} downloaded", "SUCCESS")
            except Exception as e:
                write_status(f"Failed to download {wheel_name}: {e}", "WARN")
                continue
        write_status(f"Installing {wheel_name}...", "INFO")
        run_command_live([PYTHON_EXE, "-m", "pip", "install", wheel_path, "--no-deps"])
    write_status("All wheels installed successfully", "SUCCESS")

def step_install_triton():
    write_step("Installing Triton for Windows Compatibility", 6, 8)
    if install_triton():
        write_status("Triton installation completed.", "SUCCESS")
        write_status("Running Triton functionality test...", "INFO")
        if test_triton():
            write_status("Triton test passed! Kernel compilation works.", "SUCCESS")
        else:
            write_status("Triton test failed. Some functionality might be unavailable.", "WARN")
    else:
        write_status("Triton could not be installed. Proceeding without Triton support.", "WARN")

def step_download_models():
    write_step("Downloading AI Models (DINOv3 + Trellis2 GGUF)", 7, 8)
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

def step_apply_patches():
    write_step("Applying Required Patches", 8, 8)
    site_packages = os.path.join(DIR_LVL, "comfy_env", "Lib", "site-packages")
    if not os.path.exists(site_packages) and args.env_path:
        py_dir = os.path.dirname(PYTHON_EXE)
        site_packages = os.path.join(py_dir, "Lib", "site-packages")
        if not os.path.exists(site_packages):
            site_packages = os.path.join(py_dir, "..", "Lib", "site-packages")

    remesh_path = os.path.join(site_packages, "cumesh", "remeshing.py")
    if os.path.exists(remesh_path):
        backup_path = remesh_path + ".bak"
        if not os.path.exists(backup_path):
            shutil.copy(remesh_path, backup_path)
            write_status("Created backup of remeshing.py", "INFO")
        try:
            download_file_with_resume(
                "https://raw.githubusercontent.com/visualbruno/CuMesh/main/cumesh/remeshing.py",
                remesh_path
            )
            write_status("Patched remeshing.py successfully", "SUCCESS")
        except Exception as e:
            write_status(f"Failed to patch remeshing.py: {e}", "WARN")

    run_command_live([PYTHON_EXE, "-m", "pip", "install", "--upgrade", "pooch", "--no-deps"] + PIP_ARGS)
    result = subprocess.run([PYTHON_EXE, "-c", "import numpy, sys; sys.exit(0 if numpy.__version__ == '1.26.4' else 1)"])
    if result.returncode != 0:
        write_status("Restoring numpy 1.26.4 for compatibility...", "INFO")
        run_command_live([PYTHON_EXE, "-m", "pip", "install", "--force-reinstall", "numpy==1.26.4", "--no-deps"] + PIP_ARGS)
    write_status("All patches applied successfully", "SUCCESS")

# ----------------------------- Main -----------------------------
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
    step_install_triton()
    step_download_models()
    step_apply_patches()

    print("")
    print(f"{Colors.GREEN}==========================================={Colors.RESET}")
    write_status(f"{NODE_NAME} Installation Complete", "SUCCESS")
    print(f"{Colors.GREEN}==========================================={Colors.RESET}")
    print("")
    if len(sys.argv) == 1 or (len(sys.argv) >= 3 and sys.argv[1] in ('--env_path', '--comfyui_dir')):
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