#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path
from urllib.request import urlopen


RELEASES_URL = "https://www.kernel.org/releases.json"
PKGBUILD_PATH = Path(__file__).resolve().parent.parent / "PKGBUILD"
CONFIG_PATH = Path(__file__).resolve().parent.parent / "config"


def parse_version(version: str) -> tuple[int, ...]:
    return tuple(int(part) for part in version.split("."))


def fetch_latest_longterm(url: str) -> str:
    with urlopen(url) as response:
        data = json.load(response)

    candidates = []
    for release in data.get("releases", []):
        if release.get("moniker") != "longterm":
            continue
        if release.get("iseol"):
            continue
        version = release.get("version")
        if version:
            candidates.append(version)

    if not candidates:
        raise RuntimeError("No active longterm releases found in kernel.org response")

    return max(candidates, key=parse_version)


def replace_once(text: str, pattern: str, replacement: str) -> str:
    updated, count = re.subn(pattern, replacement, text, count=1, flags=re.MULTILINE)
    if count != 1:
        raise RuntimeError(f"Expected to update exactly one match for pattern: {pattern}")
    return updated


def update_config(path: Path, latest_version: str) -> bool:
    text = path.read_text(encoding="utf-8")
    pattern = r"^(# Linux/x86 )\d+\.\d+\.\d+( Kernel Configuration)$"
    match = re.search(pattern, text, re.MULTILINE)

    if match is None:
        raise RuntimeError("Failed to read kernel version header from config")

    current_version = re.search(r"\d+\.\d+\.\d+", match.group(0))
    if current_version is None or current_version.group(0) == latest_version:
        return False

    updated = replace_once(text, pattern, rf"\g<1>{latest_version}\g<2>")
    path.write_text(updated, encoding="utf-8")
    return True


def update_pkgbuild(path: Path, latest_version: str) -> tuple[bool, str, str]:
    text = path.read_text(encoding="utf-8")

    current_basekernel_match = re.search(r"^_basekernel=(\d+\.\d+)$", text, re.MULTILINE)
    current_pkgver_match = re.search(r"^pkgver=(\d+\.\d+\.\d+)$", text, re.MULTILINE)

    if current_basekernel_match is None or current_pkgver_match is None:
        raise RuntimeError("Failed to read _basekernel or pkgver from PKGBUILD")

    current_basekernel = current_basekernel_match.group(1)
    current_pkgver = current_pkgver_match.group(1)
    latest_basekernel = ".".join(latest_version.split(".")[:2])

    if current_basekernel == latest_basekernel and current_pkgver == latest_version:
        return False, current_pkgver, latest_basekernel

    current_basever = current_basekernel.replace(".", "")
    latest_basever = latest_basekernel.replace(".", "")

    updated = replace_once(text, r"^_basekernel=\d+\.\d+$", f"_basekernel={latest_basekernel}")
    updated = replace_once(updated, r"^pkgver=\d+\.\d+\.\d+$", f"pkgver={latest_version}")
    updated = replace_once(updated, r"^pkgrel=\d+$", "pkgrel=1")
    updated = replace_once(
        updated,
        rf"^package_linux{re.escape(current_basever)}-t2\(\) {{",
        f"package_linux{latest_basever}-t2() {{",
    )
    updated = replace_once(
        updated,
        rf"^package_linux{re.escape(current_basever)}-t2-headers\(\) {{",
        f"package_linux{latest_basever}-t2-headers() {{",
    )

    path.write_text(updated, encoding="utf-8")
    return True, current_pkgver, latest_basekernel


def write_github_outputs(
    output_path: str,
    *,
    current_version: str,
    latest_version: str,
    latest_basekernel: str,
    updated: bool,
) -> None:
    with open(output_path, "a", encoding="utf-8") as handle:
        handle.write(f"current_version={current_version}\n")
        handle.write(f"latest_version={latest_version}\n")
        handle.write(f"latest_basekernel={latest_basekernel}\n")
        handle.write(f"updated={'true' if updated else 'false'}\n")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Update PKGBUILD to the latest active longterm kernel release.",
    )
    parser.add_argument("--releases-url", default=RELEASES_URL)
    parser.add_argument("--pkgbuild", type=Path, default=PKGBUILD_PATH)
    parser.add_argument("--github-output", default=os.environ.get("GITHUB_OUTPUT"))
    parser.add_argument(
        "--check",
        action="store_true",
        help="Exit with status 2 if an update is available, without modifying files.",
    )
    args = parser.parse_args()

    latest_version = fetch_latest_longterm(args.releases_url)
    text = args.pkgbuild.read_text(encoding="utf-8")
    current_pkgver_match = re.search(r"^pkgver=(\d+\.\d+\.\d+)$", text, re.MULTILINE)
    if current_pkgver_match is None:
        raise RuntimeError("Failed to read pkgver from PKGBUILD")
    current_version = current_pkgver_match.group(1)
    latest_basekernel = ".".join(latest_version.split(".")[:2])
    needs_update = current_version != latest_version

    if args.check:
        if args.github_output:
            write_github_outputs(
                args.github_output,
                current_version=current_version,
                latest_version=latest_version,
                latest_basekernel=latest_basekernel,
                updated=False,
            )
        return 2 if needs_update else 0

    updated, previous_version, latest_basekernel = update_pkgbuild(args.pkgbuild, latest_version)
    config_updated = update_config(CONFIG_PATH, latest_version)
    if args.github_output:
        write_github_outputs(
            args.github_output,
            current_version=previous_version,
            latest_version=latest_version,
            latest_basekernel=latest_basekernel,
            updated=updated or config_updated,
        )

    print(
        json.dumps(
            {
                "updated": updated or config_updated,
                "current_version": previous_version,
                "latest_version": latest_version,
                "latest_basekernel": latest_basekernel,
            }
        )
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"error: {exc}", file=sys.stderr)
        raise SystemExit(1)
