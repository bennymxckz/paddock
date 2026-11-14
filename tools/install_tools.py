"""Installs the pinned StyLua and selene versions into tools/bin/.

    python tools/install_tools.py

Downloads the official release builds for this platform from GitHub. CI runs
the same script, so formatting and lint results match everywhere. Add
tools/bin/ to your PATH, or run the tools as tools/bin/stylua and
tools/bin/selene. To update a tool, change its version here.
"""

from __future__ import annotations

import io
import os
import pathlib
import platform
import stat
import subprocess
import sys
import urllib.request
import zipfile

STYLUA_VERSION = "2.6.0"
SELENE_VERSION = "0.32.0"

ROOT = pathlib.Path(__file__).resolve().parent.parent
BIN = ROOT / "tools" / "bin"


def platform_key() -> str:
    system = platform.system()
    machine = platform.machine().lower()
    if system == "Windows":
        return "windows"
    if system == "Linux":
        return "linux-aarch64" if machine in ("aarch64", "arm64") else "linux"
    if system == "Darwin":
        return "macos-aarch64" if machine in ("arm64", "aarch64") else "macos"
    sys.exit(
        f"error: no prebuilt tools for {system} {machine}; install StyLua {STYLUA_VERSION} "
        f"and selene {SELENE_VERSION} yourself (see CONTRIBUTING.md)"
    )


def assets(key: str) -> list[tuple[str, str]]:
    """(tool name, download URL) for this platform."""
    stylua = {
        "windows": "stylua-windows-x86_64.zip",
        "linux": "stylua-linux-x86_64.zip",
        "linux-aarch64": "stylua-linux-aarch64.zip",
        "macos": "stylua-macos-x86_64.zip",
        "macos-aarch64": "stylua-macos-aarch64.zip",
    }[key]
    # selene ships one macOS build and no Linux arm build.
    selene_os = {"windows": "windows", "linux": "linux", "macos": "macos", "macos-aarch64": "macos"}.get(key)
    if selene_os is None:
        sys.exit(
            f"error: selene has no prebuilt release for {key}; install it with "
            f"`cargo install selene --version {SELENE_VERSION} --locked`"
        )
    return [
        ("stylua", f"https://github.com/JohnnyMorganz/StyLua/releases/download/v{STYLUA_VERSION}/{stylua}"),
        (
            "selene",
            f"https://github.com/Kampfkarren/selene/releases/download/{SELENE_VERSION}/"
            f"selene-{SELENE_VERSION}-{selene_os}.zip",
        ),
    ]


def exe(name: str) -> pathlib.Path:
    return BIN / (name + (".exe" if platform.system() == "Windows" else ""))


def installed_version(name: str) -> str | None:
    path = exe(name)
    if not path.is_file():
        return None
    out = subprocess.run([str(path), "--version"], capture_output=True, text=True, check=False).stdout
    return out.split()[-1] if out.strip() else None


def install(name: str, url: str, version: str) -> None:
    if installed_version(name) == version:
        print(f"{name} {version} already installed")
        return
    print(f"downloading {name} {version}")
    with urllib.request.urlopen(url, timeout=60) as response:
        data = response.read()
    with zipfile.ZipFile(io.BytesIO(data)) as zf:
        member = next(m for m in zf.namelist() if pathlib.PurePosixPath(m).stem == name)
        target = exe(name)
        target.write_bytes(zf.read(member))
    target.chmod(target.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)
    print(f"installed {name} {installed_version(name)}")


def main() -> None:
    BIN.mkdir(parents=True, exist_ok=True)
    versions = {"stylua": STYLUA_VERSION, "selene": SELENE_VERSION}
    for name, url in assets(platform_key()):
        install(name, url, versions[name])
    # On GitHub Actions, put the tools on PATH for later steps.
    github_path = os.environ.get("GITHUB_PATH")
    if github_path:
        with open(github_path, "a", encoding="utf-8") as f:
            f.write(f"{BIN}\n")


if __name__ == "__main__":
    main()
