#!/usr/bin/env bash
set -euo pipefail

YABAI_BIN="${YABAI_BIN:-/opt/homebrew/bin/yabai}"

focused_id="$($YABAI_BIN -m query --windows --window | jq -r '.id')"

"$YABAI_BIN" -m query --windows --space |
  jq -r --argjson focused "$focused_id" '.[] | select(.id != $focused) | .id' |
  while IFS= read -r window_id; do
    "$YABAI_BIN" -m window "$window_id" --close >/dev/null 2>&1 || true
  done
