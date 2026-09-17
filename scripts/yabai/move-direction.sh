#!/usr/bin/env bash
set -euo pipefail

YABAI_BIN="${YABAI_BIN:-/opt/homebrew/bin/yabai}"

case "${1:-}" in
  north|east|south|west) direction="$1" ;;
  *) exit 2 ;;
esac

if "$YABAI_BIN" -m window --warp "$direction" >/dev/null 2>&1; then
  exit 0
fi

focused_window="$($YABAI_BIN -m query --windows --window 2>/dev/null || true)"
[[ -n "$focused_window" ]] || exit 0
focused_id="$(printf '%s\n' "$focused_window" | jq -r '.id')"
focused_display="$(printf '%s\n' "$focused_window" | jq -r '.display')"

target_display="$(
  "$YABAI_BIN" -m query --displays |
    jq -r --arg direction "$direction" --argjson focused_display "$focused_display" '
      def cx: .frame.x + (.frame.w / 2);
      def cy: .frame.y + (.frame.h / 2);
      def absolute: if . < 0 then -. else . end;
      def overlap_x($a; $b):
        ($a.frame.x < ($b.frame.x + $b.frame.w)) and
        ($b.frame.x < ($a.frame.x + $a.frame.w));
      def overlap_y($a; $b):
        ($a.frame.y < ($b.frame.y + $b.frame.h)) and
        ($b.frame.y < ($a.frame.y + $a.frame.h));
      def is_directional($candidate; $focused):
        if $direction == "west" then ($candidate | cx) < ($focused | cx)
        elif $direction == "east" then ($candidate | cx) > ($focused | cx)
        elif $direction == "north" then ($candidate | cy) < ($focused | cy)
        else ($candidate | cy) > ($focused | cy)
        end;
      def score($candidate; $focused):
        if ($direction == "west" or $direction == "east") then
          [(if overlap_y($candidate; $focused) then 0 else 1 end),
           ((($candidate | cx) - ($focused | cx)) | absolute),
           ((($candidate | cy) - ($focused | cy)) | absolute)]
        else
          [(if overlap_x($candidate; $focused) then 0 else 1 end),
           ((($candidate | cy) - ($focused | cy)) | absolute),
           ((($candidate | cx) - ($focused | cx)) | absolute)]
        end;
      [.[]] as $displays |
      ($displays | map(select(.index == $focused_display)) | first) as $focused |
      $displays |
      map(select(.index != $focused_display)) |
      map(select(is_directional(.; $focused)) | {index, score: score(.; $focused)}) |
      sort_by(.score) |
      .[0].index // empty
    '
)"

[[ -n "$target_display" ]] || exit 0
"$YABAI_BIN" -m window "$focused_id" --display "$target_display"
"$YABAI_BIN" -m window --focus "$focused_id" >/dev/null 2>&1 || true
