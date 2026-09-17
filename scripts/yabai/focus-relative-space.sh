#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
  prev|next) direction="$1" ;;
  *) exit 2 ;;
esac

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck disable=SC1091
. "$script_dir/lib.sh"

current_label="$($YABAI_BIN -m query --spaces --space | jq -r '.label // empty')"
current_workspace="${current_label#ws-}"
target_workspace="$(relative_workspace "$current_workspace" "$direction")"

"$script_dir/focus-space.sh" "$target_workspace"
