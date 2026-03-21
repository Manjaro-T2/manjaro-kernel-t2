#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
Usage: ./cleanup.sh [--dry-run]

Remove untracked residue left by PKGBUILD and makepkg:
- downloaded source archives and VCS checkouts declared in PKGBUILD
- makepkg work directories (`src/`, `pkg/`)
- built package archives and signatures
EOF
}

dry_run=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--dry-run)
      dry_run=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

cd "${repo_root}"

if [[ ! -f PKGBUILD ]]; then
  echo "error: PKGBUILD not found in ${repo_root}" >&2
  exit 1
fi

declare -a candidates=()

add_candidate() {
  local path="$1"

  [[ -e "${path}" || -L "${path}" ]] || return 0

  candidates+=("${path}")
}

is_tracked() {
  git ls-files --error-unmatch -- "$1" >/dev/null 2>&1
}

mapfile -t source_entries < <(
  set +u
  source "${repo_root}/PKGBUILD"
  printf '%s\n' "${source[@]}"
)

for src in "${source_entries[@]}"; do
  src="${src%%::*}"
  src="${src##*/}"

  if is_tracked "${src}"; then
    continue
  fi

  add_candidate "${src}"
done

for path in src pkg; do
  add_candidate "${path}"
done

shopt -s nullglob
for artifact in *.pkg.tar.* *.pkg.tar.*.sig *.src.tar.* *.src.tar.*.sig; do
  add_candidate "${artifact}"
done
shopt -u nullglob

if [[ ${#candidates[@]} -eq 0 ]]; then
  echo "Nothing to clean."
  exit 0
fi

mapfile -t candidates < <(printf '%s\n' "${candidates[@]}" | awk '!seen[$0]++')

if (( dry_run )); then
  printf 'Would remove:\n'
else
  printf 'Removing:\n'
fi

for path in "${candidates[@]}"; do
  printf '  %s\n' "${path}"
done

if (( dry_run )); then
  exit 0
fi

for path in "${candidates[@]}"; do
  rm -rf -- "${path}"
done
