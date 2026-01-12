r"""
Compare installed package versions against pinned versions in requirements.txt and environment.yml.
Run this with the Python interpreter you want to check (e.g., the project's .venv310 python).

Usage example (PowerShell):
C:/Users/swkan/Downloads/VSCode/Big Data Group Project/.venv310/Scripts/python.exe scripts/check_deps.py
"""
from __future__ import annotations
import json
import re
from pathlib import Path
from typing import Dict, Optional

try:
    # Python 3.8+: importlib.metadata is in standard lib
    from importlib.metadata import version, PackageNotFoundError
except Exception:
    from importlib_metadata import version, PackageNotFoundError  # type: ignore

ROOT = Path(__file__).resolve().parents[1]
REQ_FILE = ROOT / "requirements.txt"
ENV_FILE = ROOT / "environment.yml"
OUT_DIR = ROOT / "results"
OUT_DIR.mkdir(parents=True, exist_ok=True)


def parse_requirements(req_path: Path) -> Dict[str, str]:
    """Parse requirements.txt for exact pins (pkg==x.y.z)"""
    pins = {}
    if not req_path.exists():
        return pins
    with req_path.open('r', encoding='utf-8') as fh:
        for line in fh:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            m = re.match(r"^([A-Za-z0-9_.-]+)==([0-9a-zA-Z.+-]+)", line)
            if m:
                pins[m.group(1).lower()] = m.group(2)
    return pins


def parse_environment_yml(env_path: Path) -> Dict[str, str]:
    """Parse environment.yml for pinned versions; extract conda pins (pkg=1.2.3) and pip pins beneath - pip: section"""
    pins = {}
    if not env_path.exists():
        return pins
    text = env_path.read_text(encoding='utf-8')
    # Conda-style pins: name=ver
    for m in re.finditer(r"^\s*-\s*([A-Za-z0-9_.-]+)=([0-9a-zA-Z.+-]+)\s*$", text, flags=re.MULTILINE):
        pins[m.group(1).lower()] = m.group(2)
    # pip block: find list under 'pip:' tag
    pip_block_match = re.search(r"^-\s*pip:\s*$([\s\S]*)^([^-\s]|$)", text, flags=re.MULTILINE)
    if pip_block_match:
        pip_block = pip_block_match.group(1)
    else:
        # simpler fallback: find lines under '- pip:' until indent changes or EOF
        lines = text.splitlines()
        pip_block = ""
        in_pip = False
        for li in lines:
            if re.match(r"^\s*-\s*pip:\s*$", li):
                in_pip = True
                continue
            if in_pip:
                if re.match(r"^\s*-\s*[A-Za-z0-9]", li):
                    pip_block += li + "\n"
                else:
                    # stop if line is not an indented pip item
                    if not re.match(r"^\s{4,}-\s*", li):
                        break
                    pip_block += li + "\n"
    # Parse pip pins like `pkg==x.y.z`
    for line in pip_block.splitlines():
        m = re.match(r"^\s*-\s*([A-Za-z0-9_.-]+)==([0-9a-zA-Z.+-]+)\s*$", line)
        if m:
            pins[m.group(1).lower()] = m.group(2)
    return pins


# robustness: also check environment.yml by a simple line-by-line scan for 'pyspark==...'


def check_installed_version(pkg_name: str) -> Optional[str]:
    """Return installed distribution version via importlib.metadata (safe)."""
    try:
        return version(pkg_name)
    except PackageNotFoundError:
        return None
    except Exception:
        # fallback: sometimes package name differs from distribution
        # try some common distribution<->module mapping
        alt = {
            'pyspark': 'pyspark',
            'vadersentiment': 'vaderSentiment',
            'vaderSentiment': 'vaderSentiment',
        }
        try:
            return version(alt.get(pkg_name.lower(), pkg_name))
        except Exception:
            return None


if __name__ == '__main__':
    req_pins = parse_requirements(REQ_FILE)
    env_pins = parse_environment_yml(ENV_FILE)
    # Merge pins (requirements.txt preferred for pip; env pins for other libs)
    pins = {**env_pins}
    pins.update(req_pins)

    checked = {}
    misses = {}
    mismatches = {}

    print('Expected pins (from requirements.txt & environment.yml):')
    for k, v in sorted(pins.items()):
        print(f" - {k} == {v}")

    print('\nChecking installed package versions (via importlib.metadata)...')
    for pkg, expected in sorted(pins.items()):
        installed = check_installed_version(pkg)
        checked[pkg] = {'expected': expected, 'installed': installed}
        if installed is None:
            misses[pkg] = {'expected': expected}
        else:
            # Compare prefix of version numbers; exact match preferred
            if installed != expected:
                mismatches[pkg] = {'expected': expected, 'installed': installed}

    # Additional heuristic checks for compiled libs and ABI compatibility
    abi_warnings = []
    numpy_v = checked.get('numpy', {}).get('installed')
    pandas_v = checked.get('pandas', {}).get('installed')
    pyarrow_v = checked.get('pyarrow', {}).get('installed')
    if numpy_v and pandas_v:
        try:
            n_major = int(numpy_v.split('.')[0])
            p_major = int(pandas_v.split('.')[0])
            if n_major >= 2 and p_major < 2:
                abi_warnings.append(f"NumPy {numpy_v} vs pandas {pandas_v} — ABI mismatch risk (pandas < 2 and numpy >= 2)")
        except Exception:
            pass
    if pyarrow_v and tuple(int(x) for x in pyarrow_v.split('.')[:2]) < (11, 0):
        abi_warnings.append(f"PyArrow {pyarrow_v} is less than recommended 11.0.0 for Spark 3.5.x features")

    # Summary
    ok = {k:v for k,v in checked.items() if v['installed'] and v['installed'] == v['expected']}
    with open(OUT_DIR / 'deps_check.json', 'w', encoding='utf-8') as fh:
        json.dump({'checked': checked, 'mismatches': mismatches, 'misses': misses, 'abi_warnings': abi_warnings}, fh, indent=2)

    print('\nResults written to results/deps_check.json')
    print('\nSummary:')
    print(f" - OK (matching versions): {len(ok)}")
    print(f" - Missing packages: {len(misses)}")
    print(f" - Version mismatches: {len(mismatches)}")
    if abi_warnings:
        print('\nABI & compatibility warnings:')
        for w in abi_warnings:
            print('  -', w)
    # Print lists for quick viewing
    if misses:
        print('\nMissing packages:')
        for k in sorted(misses):
            print(' -', k, 'expected:', misses[k]['expected'])
    if mismatches:
        print('\nPackages with version mismatches:')
        for k in sorted(mismatches):
            print(' -', k, 'installed:', mismatches[k]['installed'], 'expected:', mismatches[k]['expected'])

    # exit status
    if misses or mismatches or abi_warnings:
        print('\nSome dependency issues detected — see results/deps_check.json for details.')
        raise SystemExit(2)
    else:
        print('\nAll pinned dependencies appear installed with expected versions.')
        raise SystemExit(0)
