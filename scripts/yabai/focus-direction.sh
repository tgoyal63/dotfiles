#!/usr/bin/env bash
set -euo pipefail

YABAI_BIN="${YABAI_BIN:-/opt/homebrew/bin/yabai}"

case "${1:-}" in
  north|east|south|west) direction="$1" ;;
  *) exit 2 ;;
esac

windows_json="$($YABAI_BIN -m query --windows)"
target_id="$(
  printf '%s\n' "$windows_json" |
    jq -r --arg direction "$direction" '
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
      def directional_score($candidate; $focused):
        if ($direction == "west" or $direction == "east") then
          [(if overlap_y($candidate; $focused) then 0 else 1 end),
           ((($candidate | cx) - ($focused | cx)) | absolute),
           ((($candidate | cy) - ($focused | cy)) | absolute)]
        else
          [(if overlap_x($candidate; $focused) then 0 else 1 end),
           ((($candidate | cy) - ($focused | cy)) | absolute),
           ((($candidate | cx) - ($focused | cx)) | absolute)]
        end;
      def wrap_score($candidate; $focused):
        if $direction == "west" then [-($candidate | cx), ((($candidate | cy) - ($focused | cy)) | absolute)]
        elif $direction == "east" then [($candidate | cx), ((($candidate | cy) - ($focused | cy)) | absolute)]
        elif $direction == "north" then [-($candidate | cy), ((($candidate | cx) - ($focused | cx)) | absolute)]
        else [($candidate | cy), ((($candidate | cx) - ($focused | cx)) | absolute)]
        end;

      ([.[] | select(."has-focus" == true)] | first) as $focused |
      if $focused == null then empty else
        [.[] |
          select(.id != $focused.id) |
          select(."is-visible" == true) |
          select(."is-minimized" == false) |
          select(."is-hidden" == false) |
          select(.role == "AXWindow") |
          select(.subrole == "AXStandardWindow")] as $candidates |
        (($candidates |
          map(select(is_directional(.; $focused)) | {id, score: directional_score(.; $focused)}) |
          sort_by(.score) |
          .[0].id) //
         ($candidates |
          map({id, score: wrap_score(.; $focused)}) |
          sort_by(.score) |
          .[0].id) // empty)
      end
    '
)"

[[ -n "$target_id" ]] || exit 0
"$YABAI_BIN" -m window --focus "$target_id"
