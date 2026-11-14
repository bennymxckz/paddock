"""Builds the Paddock mod zip from src/.

    python tools/build.py                 # writes dist/paddock.zip
    python tools/build.py --version       # prints the version from the source
    python tools/build.py --check-tag v0.1.0
                                          # fails unless the tag matches the version
    python tools/build.py --notes         # prints this version's CHANGELOG section

The zip is deterministic: entries are sorted and carry a fixed timestamp, so
the same source always gives a byte-identical zip. The MIT notice travels in
the header of paddock.lua (BeamNG's repository doesn't allow readme files in
mods), and the build fails if it's missing or differs from LICENSE.
"""

from __future__ import annotations

import argparse
import pathlib
import re
import sys
import zipfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "src"
DIST = ROOT / "dist"
EXTENSION = SRC / "lua" / "ge" / "extensions" / "paddock.lua"
LICENSE = ROOT / "LICENSE"
ZIP_NAME = "paddock.zip"
FIXED_TIME = (2020, 1, 1, 0, 0, 0)


def version() -> str:
    text = EXTENSION.read_text(encoding="utf-8")
    match = re.search(r'^M\.version\s*=\s*"([^"]+)"', text, re.MULTILINE)
    if not match:
        sys.exit(f"error: no M.version in {EXTENSION.relative_to(ROOT)}")
    return match.group(1)


def notes(ver: str) -> str:
    """The body of the `## [ver]` section in CHANGELOG.md."""
    text = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8")
    match = re.search(
        rf"^## \[{re.escape(ver)}\][^\n]*\n(.*?)(?=^## \[|^\[[^\]]+\]:|\Z)", text, re.MULTILINE | re.DOTALL
    )
    if not match or not match.group(1).strip():
        sys.exit(f"error: CHANGELOG.md has no entries for {ver}")
    return match.group(1).strip()


def add(zf: zipfile.ZipFile, name: str, data: bytes) -> None:
    info = zipfile.ZipInfo(name, FIXED_TIME)
    info.compress_type = zipfile.ZIP_DEFLATED
    info.external_attr = 0o644 << 16
    zf.writestr(info, data)


def check_license() -> None:
    """The license text in paddock.lua's header must match LICENSE."""
    lines = []
    for line in EXTENSION.read_text(encoding="utf-8").splitlines():
        if not line.startswith("--"):
            break
        lines.append(line[3:] if line.startswith("-- ") else "")
    if LICENSE.read_text(encoding="utf-8").strip() not in "\n".join(lines):
        sys.exit(f"error: the license in the header of {EXTENSION.relative_to(ROOT)} doesn't match LICENSE")


def build() -> pathlib.Path:
    check_license()
    DIST.mkdir(exist_ok=True)
    out = DIST / ZIP_NAME
    files = sorted(p for p in SRC.rglob("*") if p.is_file())
    with zipfile.ZipFile(out, "w") as zf:
        for path in files:
            add(zf, path.relative_to(SRC).as_posix(), path.read_bytes())
    return out


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--version", action="store_true", help="print the version and exit")
    parser.add_argument("--check-tag", metavar="TAG", help="fail unless TAG is v<version>")
    parser.add_argument("--notes", action="store_true", help="print this version's CHANGELOG section and exit")
    args = parser.parse_args()

    if args.version:
        print(version())
        return
    if args.notes:
        print(notes(version()))
        return
    if args.check_tag:
        expected = f"v{version()}"
        if args.check_tag != expected:
            sys.exit(f"error: tag {args.check_tag} doesn't match the source version ({expected})")
        print(f"tag {args.check_tag} matches the source version")
        return

    out = build()
    print(f"{out.relative_to(ROOT).as_posix()}  Paddock {version()}  {out.stat().st_size} bytes")


if __name__ == "__main__":
    main()
