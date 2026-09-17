#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck disable=SC1091
. "$script_dir/lib.sh"

focused_display="$($YABAI_BIN -m query --displays --display | jq -r '.index')"
target_display="$(
  "$YABAI_BIN" -m query --displays |
    jq -r --argjson current "$focused_display" '
      [.[].index] | sort as $displays |
      if ($displays | length) < 2 then empty
      else $displays[((($displays | index($current)) + 1) % ($displays | length))]
      end
    '
)"
[[ -n "$target_display" ]] || exit 0

"$YABAI_BIN" -m query --windows |
  jq -r --argjson display "$focused_display" '.[] | select(.display == $display) | [.id, .pid] | @tsv' |
  while IFS=$'\t' read -r window_id pid; do
    bundle_id="$(bundle_id_for_pid "$pid")"
    if is_screen_share_private_app "$bundle_id"; then
      "$YABAI_BIN" -m window "$window_id" --display "$target_display" >/dev/null 2>&1 || true
    fi
  done
