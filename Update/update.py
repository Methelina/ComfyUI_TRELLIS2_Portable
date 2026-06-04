import pygit2
from datetime import datetime
import sys
import os
import shutil
import filecmp
import subprocess
import pathlib

# ----------------------------------------------------------------------
# Поиск uv.exe (в корне проекта)
# ----------------------------------------------------------------------
def get_uv_exe():
    script_dir = pathlib.Path(__file__).resolve().parent   # папка update/
    uv_in_root = script_dir.parent / "uv.exe"
    if uv_in_root.exists():
        return str(uv_in_root)
    return "uv"

UV_EXE = get_uv_exe()

# ----------------------------------------------------------------------
# Портабельные кэши uv
# ----------------------------------------------------------------------
os.environ.setdefault("UV_CACHE_DIR", str(pathlib.Path(__file__).parent.parent / ".cache" / "uv"))
os.environ.setdefault("UV_NO_PROGRESS", "1")

# ----------------------------------------------------------------------
# Git pull через pygit2
# ----------------------------------------------------------------------
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
                        print('Conflicts found in:', conflict[0].path)
                    raise AssertionError('Conflicts, ahhhhh!!')
                user = repo.default_signature
                tree = repo.index.write_tree()
                repo.create_commit('HEAD', user, user, 'Merge!', tree,
                                   [repo.head.target, remote_master_id])
                repo.state_cleanup()
            else:
                raise AssertionError('Unknown merge analysis result')

# ----------------------------------------------------------------------
# Установка через uv pip
# ----------------------------------------------------------------------
def uv_pip_install(package_spec, python_exe):
    cmd = [UV_EXE, "pip", "install", "--python", python_exe] + package_spec.split()
    print(f"   > {' '.join(cmd)}")
    subprocess.check_call(cmd)

# ----------------------------------------------------------------------
# Основная логика
# ----------------------------------------------------------------------
pygit2.option(pygit2.GIT_OPT_SET_OWNER_VALIDATION, 0)

repo_path = str(sys.argv[1])          # ..\ComfyUI
repo = pygit2.Repository(repo_path)
ident = pygit2.Signature('comfyui', 'comfy@ui')

# stash
try:
    print("stashing current changes")
    repo.stash(ident)
except KeyError:
    print("nothing to stash")

# backup branch
backup_branch_name = f'backup_branch_{datetime.today().strftime("%Y-%m-%d_%H_%M_%S")}'
print(f"creating backup branch: {backup_branch_name}")
try:
    repo.branches.local.create(backup_branch_name, repo.head.peel())
except:
    pass

# checkout master
print("checking out master branch")
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

print("pulling latest changes")
pull(repo)

# stable tag
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

print("Done!")

# ----------------------------------------------------------------------
# Установка/обновление зависимостей из requirements.txt
# ----------------------------------------------------------------------
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
        print(f"Failed to install requirements: {e}")