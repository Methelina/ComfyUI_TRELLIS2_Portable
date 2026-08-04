import re
import sys

def parse_settings(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    env_name = re.search(r'env_name:\s*"(.+?)"', content)
    env_name = env_name.group(1) if env_name else 'comfy_env'

    python_version = re.search(r'python_version:\s*"(.+?)"', content)
    python_version = python_version.group(1) if python_version else '3.12'

    comfy_dir = re.search(r'comfy_dir:\s*"(.+?)"', content)
    comfy_dir = comfy_dir.group(1) if comfy_dir else 'ComfyUI'

    print(f'set "ENV_NAME={env_name}"')
    print(f'set "PYTHON_VERSION={python_version}"')
    print(f'set "COMFY_DIR={comfy_dir}"')

    wheels_match = re.search(r'wheels:([\s\S]*?)(?=nodes:|pypi_packages:|\Z)', content)
    wheels = []
    if wheels_match:
        block = wheels_match.group(1)
        pattern = r'^\s*([a-z_][a-z_0-9]*):\s*\n\s*url:\s*"([^"]+)"\s*\n?\s*no_deps:\s*(true|false)'
        for m in re.finditer(pattern, block, re.MULTILINE):
            wheels.append((m.group(1), m.group(2), m.group(3)))

    print(f'set "WHEEL_COUNT={len(wheels)}"')
    for i, (name, url, nodeps) in enumerate(wheels, 1):
        print(f'set "WHEEL_{i}_NAME={name}"')
        print(f'set "WHEEL_{i}_URL={url}"')
        print(f'set "WHEEL_{i}_NODEPS={nodeps}"')

    nodes_match = re.search(r'nodes:([\s\S]*?)(?=wheels:|pypi_packages:|\Z)', content)
    nodes = []
    if nodes_match:
        block = nodes_match.group(1)
        pattern = r'- url:\s*"([^"]+)"\s*\n\s*name:\s*"([^"]+)"'
        for m in re.finditer(pattern, block, re.MULTILINE):
            nodes.append((m.group(1), m.group(2)))

    print(f'set "NODE_COUNT={len(nodes)}"')
    for i, (url, name) in enumerate(nodes, 1):
        print(f'set "NODE_{i}_URL={url}"')
        print(f'set "NODE_{i}_NAME={name}"')

    pypi_match = re.search(r'pypi_packages:([\s\S]*?)(?=\Z|wheels:|nodes:)', content)
    pypi = []
    if pypi_match:
        block = pypi_match.group(1)
        pattern = r'- name:\s*"([^"]+)"(?:\s*\n\s*url:\s*"([^"]+)")?'
        for m in re.finditer(pattern, block, re.MULTILINE):
            name = m.group(1)
            url = m.group(2) if m.group(2) else ''
            pypi.append((name, url))

    print(f'set "PYPI_COUNT={len(pypi)}"')
    for i, (name, url) in enumerate(pypi, 1):
        print(f'set "PYPI_{i}_NAME={name}"')
        print(f'set "PYPI_{i}_URL={url}"')

if __name__ == '__main__':
    parse_settings(sys.argv[1] if len(sys.argv) > 1 else 'settings.yaml')
