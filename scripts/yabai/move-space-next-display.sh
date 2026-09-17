#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck disable=SC1091
. "$script_dir/lib.sh"

source_space="$($YABAI_BIN -m query --spaces --space)"
source_label="$(printf '%s\n' "$source_space" | jq -r '.label // empty')"
source_workspace="${source_label#ws-}"
source_id="$(printf '%s\n' "$source_space" | jq -r '.id')"
source_display="$(printf '%s\n' "$source_space" | jq -r '.display')"
target_display="$(
  "$YABAI_BIN" -m query --displays |
    jq -r --argjson source "$source_display" '
      [.[].index] | sort as $displays |
      if ($displays | length) < 2 then empty
      else $displays[((($displays | index($source)) + 1) % ($displays | length))]
      end
    '
)"

[[ -n "$source_label" && "$source_label" == ws-* ]] || {
  printf '%s\n' 'The focused native Space is not a managed logical workspace.' >&2
  exit 1
}
[[ -n "$target_display" ]] || exit 0

source_space_count="$(
  "$YABAI_BIN" -m query --spaces |
    jq -r --argjson display "$source_display" \
      '[.[] | select(.display == $display and ."is-native-fullscreen" == false)] | length'
)"
placeholder_index=""

# macOS requires every display to retain at least one user Space. Create an
# empty placeholder before moving the only Space instead of swapping another
# display's active Space into its place.
if [[ "$source_space_count" -eq 1 ]]; then
  if ! "$YABAI_BIN" -m space --create "$source_display"; then
    printf '%s\n' \
      'Unable to create a placeholder Space. The yabai scripting addition must be active; nothing was moved.' \
      >&2
    exit 1
  fi

  placeholder_index="$(
    "$YABAI_BIN" -m query --spaces |
      jq -r --argjson display "$source_display" --argjson source_id "$source_id" \
        '[.[] | select(.display == $display and .id != $source_id and ."is-native-fullscreen" == false)] | last | .index // empty'
  )"
fi

move_error=""
if ! move_error="$("$YABAI_BIN" -m space "$source_label" --display "$target_display" 2>&1)"; then
  if [[ -n "$placeholder_index" ]]; then
    "$YABAI_BIN" -m space "$placeholder_index" --destroy >/dev/null 2>&1 || true
  fi
  printf 'Unable to move this Space; no other active Space was moved%s%s\n' \
    "${move_error:+: }" "$move_error" >&2
  exit 1
fi

"$script_dir/focus-space.sh" "$source_workspace"
