import pygit2
from datetime import datetime
import sys
import os
import shutil
import filecmp
import subprocess
import pathlib
import importlib.metadata
import platform
import ctypes

def enable_ansi_support():
    if sys.platform == "win32":
        try:
            kernel32 = ctypes.windll.kernel32
            handle = kernel32.GetStdHandle(-11)
            mode = ctypes.c_ulong()
            kernel32.GetConsoleMode(handle, ctypes.byref(mode))
            kernel32.SetConsoleMode(handle, mode.value | 0x0004)
        except:
            pass

enable_ansi_support()

RESET = "\033[0m"
GREEN = "\033[92m"
YELLOW = "\033[93m"
CYAN = "\033[96m"
RED = "\033[91m"
BOLD = "\033[1m"

def cprint(text, color=RESET, bold=False):
    prefix = BOLD if bold else ""
    print(f"{prefix}{color}{text}{RESET}")

def get_uv_exe():
    script_dir = pathlib.Path(__file__).resolve().parent
    uv_in_root = script_dir.parent / "uv.exe"
    if uv_in_root.exists():
        return str(uv_in_root)
    return "uv"

UV_EXE = get_uv_exe()

os.environ.setdefault("UV_CACHE_DIR", str(pathlib.Path(__file__).parent.parent / ".cache" / "uv"))
os.environ.setdefault("UV_NO_PROGRESS", "1")

def pull(repo, remote_name='origin', branch='master'):
    for remote in repo.remotes:
        if remote.name == remote_name:
            remote.fetch()
            remote_master_id = repo.lookup_reference(f'refs/remotes/origin/{branch}').target
            merge_result, _ = repo.merge_analysis(remote_master_id)
            if merge_result & pygit2.GIT_MERGE_ANALYSIS_UP_TO_DATE:
                return
            elif merge_result & pygit2.GIT_MERGE_ANALYSIS_FASTFORWARD:
                repo.checkout_tree(repo.get(remote_master_id))
                try:
                    master_ref = repo.lookup_reference(f'refs/heads/{branch}')
                    master_ref.set_target(remote_master_id)
                except KeyError:
                    repo.create_branch(branch, repo.get(remote_master_id))
                repo.head.set_target(remote_master_id)
            elif merge_result & pygit2.GIT_MERGE_ANALYSIS_NORMAL:
                repo.merge(remote_master_id)
                if repo.index.conflicts is not None:
                    for conflict in repo.index.conflicts:
                        cprint(f'Conflicts found in: {conflict[0].path}', RED)
                    raise AssertionError('Conflicts, ahhhhh!!')
                user = repo.default_signature
                tree = repo.index.write_tree()
                repo.create_commit('HEAD', user, user, 'Merge!', tree,
                                   [repo.head.target, remote_master_id])
                repo.state_cleanup()
            else:
                raise AssertionError('Unknown merge analysis result')

def uv_pip_install(package_spec, python_exe):
    cmd = [UV_EXE, "pip", "install", "--python", python_exe] + package_spec.split()
    cprint(f"   > {' '.join(cmd)}", CYAN)
    subprocess.check_call(cmd)

def get_package_version(package_name):
    try:
        return importlib.metadata.version(package_name)
    except:
        return None

def get_comfyui_version():
    try:
        repo_path = str(sys.argv[1]) if len(sys.argv) > 1 else "ComfyUI"
        comfyui_path = os.path.abspath(repo_path)
        if comfyui_path not in sys.path:
            sys.path.insert(0, comfyui_path)
        import comfyui_version
        return comfyui_version.__version__
    except:
        return None

def get_gpu_info():
    gpu_name = "Unknown"
    memory_total = ""
    try:
        if sys.platform == "win32":
            nvidia_smi = subprocess.run(
                ["nvidia-smi", "--query-gpu=name,memory.total", "--format=csv,noheader"],
                capture_output=True, text=True, encoding='utf-8', errors='ignore'
            )
        else:
            nvidia_smi = subprocess.run(
                ["nvidia-smi", "--query-gpu=name,memory.total", "--format=csv,noheader"],
                capture_output=True, text=True
            )
        if nvidia_smi.returncode == 0:
            lines = nvidia_smi.stdout.strip().split('\n')
            if lines:
                name, mem = lines[0].split(', ')
                gpu_name = name.strip()
                memory_total = mem.strip()
    except FileNotFoundError:
        pass
    return gpu_name, memory_total

def get_env_summary():
    python_ver = f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}"
    comfyui_ver = get_comfyui_version()
    aimdo_ver = get_package_version("comfy-aimdo")
    kitchen_ver = get_package_version("comfy-kitchen")
    torch_ver = get_package_version("torch")
    xformers_ver = get_package_version("xformers")
    frontend_ver = get_package_version("comfyui-frontend-package")
    gpu_name, gpu_mem = get_gpu_info()
    os_info = f"{platform.system()}-{platform.release()}"
    return {
        "python": python_ver,
        "comfyui": comfyui_ver or "unknown",
        "comfy-aimdo": aimdo_ver or "not installed",
        "comfy-kitchen": kitchen_ver or "not installed",
        "torch": torch_ver or "not installed",
        "xformers": xformers_ver or "not installed",
        "comfyui-frontend-package": frontend_ver or "not installed",
        "gpu": f"{gpu_name} ({gpu_mem})" if gpu_mem else gpu_name,
        "os": os_info,
    }

def print_summary(summary):
    cprint("============================================================", GREEN, bold=True)
    cprint("ENVIRONMENT SUMMARY", GREEN, bold=True)
    cprint("============================================================", GREEN, bold=True)
    cprint(f"Python       : {summary['python']}", CYAN)
    cprint(f"ComfyUI      : {summary['comfyui']}", CYAN)
    cprint(f"comfy-aimdo  : {summary['comfy-aimdo']}", CYAN)
    cprint(f"comfy-kitchen: {summary['comfy-kitchen']}", CYAN)
    cprint(f"torch        : {summary['torch']}", CYAN)
    cprint(f"xformers     : {summary['xformers']}", CYAN)
    cprint(f"comfyui-frontend-package: {summary['comfyui-frontend-package']}", CYAN)
    cprint(f"GPU          : {summary['gpu']}", CYAN)
    cprint(f"OS           : {summary['os']}", CYAN)
    cprint("============================================================", GREEN, bold=True)

def print_diff(before, after):
    changes = []
    for key in ["comfyui", "comfy-aimdo", "comfy-kitchen", "torch", "xformers", "comfyui-frontend-package"]:
        old = before.get(key, "unknown")
        new = after.get(key, "unknown")
        if old != new:
            changes.append(f"  {key}: {old} -> {new}")
    if changes:
        cprint("\nVersions updated:", YELLOW, bold=True)
        for line in changes:
            cprint(line, GREEN)
    else:
        cprint("\nAll versions unchanged.", GREEN)

pygit2.option(pygit2.GIT_OPT_SET_OWNER_VALIDATION, 0)

repo_path = str(sys.argv[1])
repo = pygit2.Repository(repo_path)
ident = pygit2.Signature('comfyui', 'comfy@ui')

cprint("Collecting environment before update...", CYAN)
before_summary = get_env_summary()
print_summary(before_summary)

try:
    cprint("stashing current changes", YELLOW)
    repo.stash(ident)
except KeyError:
    cprint("nothing to stash", YELLOW)

backup_branch_name = f'backup_branch_{datetime.today().strftime("%Y-%m-%d_%H_%M_%S")}'
cprint(f"creating backup branch: {backup_branch_name}", YELLOW)
try:
    repo.branches.local.create(backup_branch_name, repo.head.peel())
except:
    pass

cprint("checking out master branch", YELLOW)
branch = repo.lookup_branch('master')
if branch is None:
    ref = repo.lookup_reference('refs/remotes/origin/master')
    repo.checkout(ref)
    branch = repo.lookup_branch('master')
    if branch is None:
        repo.create_branch('master', repo.get(ref.target))
else:
    ref = repo.lookup_reference(branch.name)
    repo.checkout(ref)

cprint("pulling latest changes", YELLOW)
pull(repo)

if "--stable" in sys.argv:
    def latest_tag(repo):
        versions = []
        for k in repo.references:
            try:
                prefix = "refs/tags/v"
                if k.startswith(prefix):
                    version = list(map(int, k[len(prefix):].split(".")))
                    versions.append((version[0] * 10000000000 + version[1] * 100000 + version[2], k))
            except:
                pass
        versions.sort()
        if versions:
            return versions[-1][1]
        return None
    tag = latest_tag(repo)
    if tag is not None:
        repo.checkout(tag)

cprint("Done!", GREEN)

cur_path = os.path.dirname(os.path.realpath(__file__))
req_path = os.path.join(cur_path, "current_requirements.txt")
repo_req_path = os.path.join(repo_path, "requirements.txt")

python_exe = os.path.abspath(os.path.join(cur_path, "..", "comfy_env", "Scripts", "python.exe"))
if not os.path.exists(python_exe):
    python_exe = shutil.which("python") or "python"

def files_equal(f1, f2):
    try:
        return filecmp.cmp(f1, f2, shallow=False)
    except:
        return False

if not os.path.exists(req_path) or not files_equal(repo_req_path, req_path):
    try:
        uv_pip_install(f"-r {repo_req_path}", python_exe)
        shutil.copy(repo_req_path, req_path)
    except Exception as e:
        cprint(f"Failed to install requirements: {e}", RED)

cprint("\nCollecting environment after update...", CYAN)
after_summary = get_env_summary()
print_summary(after_summary)
print_diff(before_summary, after_summary)