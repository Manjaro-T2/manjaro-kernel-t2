#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
branch="${EDGE_UPDATE_BRANCH:-edge}"
remote="${EDGE_UPDATE_REMOTE:-origin}"
python_bin="${PYTHON_BIN:-python3}"
auto_commit="${EDGE_UPDATE_AUTO_COMMIT:-1}"
auto_push="${EDGE_UPDATE_AUTO_PUSH:-0}"

cd "$repo_root"

current_branch="$(git branch --show-current)"
if [[ "$current_branch" != "$branch" ]]; then
  echo "Expected branch '$branch' but found '$current_branch'." >&2
  exit 1
fi

if ! git diff --quiet -- PKGBUILD; then
  echo "PKGBUILD has local changes. Refusing to auto-update over them." >&2
  exit 1
fi

if ! git diff --cached --quiet -- PKGBUILD; then
  echo "PKGBUILD has staged changes. Refusing to auto-update over them." >&2
  exit 1
fi

git fetch "$remote" "$branch"
git pull --ff-only "$remote" "$branch"

before_version="$(sed -n 's/^pkgver=//p' PKGBUILD)"
"$python_bin" scripts/update_edge_kernel.py
after_version="$(sed -n 's/^pkgver=//p' PKGBUILD)"

if [[ "$before_version" == "$after_version" ]]; then
  echo "No kernel update available. Current version remains $before_version."
  exit 0
fi

echo "Updated PKGBUILD from $before_version to $after_version."

if [[ "$auto_commit" != "1" ]]; then
  exit 0
fi

git add PKGBUILD
git commit -m "chore: update edge kernel to $after_version"

if [[ "$auto_push" == "1" ]]; then
  git push "$remote" "$branch"
fi
