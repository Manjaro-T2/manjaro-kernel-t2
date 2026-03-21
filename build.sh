#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v makepkg >/dev/null 2>&1; then
  echo "error: makepkg is required but was not found in PATH" >&2
  exit 1
fi

cd "${repo_root}"

args=("$@")

if [[ ${#args[@]} -eq 0 ]]; then
  args=(-sfc)
fi

exec makepkg "${args[@]}"
