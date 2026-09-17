#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck disable=SC1091
. "$script_dir/lib.sh"

"$script_dir/bootstrap-spaces.sh" --apply

"$YABAI_BIN" -m query --windows |
  jq -r '.[].id' |
  while IFS= read -r window_id; do
    "$script_dir/route-window.sh" "$window_id"
  done
