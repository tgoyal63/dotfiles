#!/usr/bin/env bash
set -euo pipefail

YABAI_BIN="${YABAI_BIN:-/opt/homebrew/bin/yabai}"

target_id="$(
  "$YABAI_BIN" -m query --windows |
    jq -r '
      [.[] |
        select(."is-visible" == true) |
        select(."is-minimized" == false) |
        select(."is-hidden" == false) |
        select(.role == "AXWindow") |
        select(.subrole == "AXStandardWindow")] |
      sort_by(.display, .frame.y, .frame.x) as $windows |
      ($windows | map(.id)) as $ids |
      ($windows | map(select(."has-focus" == true)) | first | .id) as $focused_id |
      if ($ids | length) == 0 then empty
      elif $focused_id == null then $ids[0]
      else $ids[((($ids | index($focused_id)) + 1) % ($ids | length))]
      end
    '
)"

[[ -n "$target_id" ]] || exit 0
"$YABAI_BIN" -m window --focus "$target_id"
