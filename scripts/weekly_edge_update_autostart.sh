#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
stamp_dir="${XDG_STATE_HOME:-$HOME/.local/state}/manjaro-t2-kernel-edge"
stamp_file="$stamp_dir/last-weekly-update"
today="$(date +%F)"
weekday="$(date +%u)"

mkdir -p "$stamp_dir"

if [[ "$weekday" != "7" ]]; then
  exit 0
fi

if [[ -f "$stamp_file" && "$(cat "$stamp_file")" == "$today" ]]; then
  exit 0
fi

"$repo_root/scripts/weekly_edge_update.sh"
printf '%s\n' "$today" > "$stamp_file"
