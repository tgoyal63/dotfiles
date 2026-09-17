#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck disable=SC1091
. "$script_dir/lib.sh"

source_space="$($YABAI_BIN -m query --spaces --space)"
source_label="$(printf '%s\n' "$source_space" | jq -r '.label // empty')"
source_workspace="${source_label#ws-}"

[[ -n "$source_label" && "$source_label" == ws-* ]] || {
  printf '%s\n' 'The focused native Space is not a managed logical workspace.' >&2
  exit 1
}

if "$YABAI_BIN" -m space --display next >/dev/null 2>&1; then
  "$script_dir/focus-space.sh" "$source_workspace"
  exit 0
fi

spaces_json="$($YABAI_BIN -m query --spaces)"
source_index="$(printf '%s\n' "$source_space" | jq -r '.index')"
source_display="$(printf '%s\n' "$source_space" | jq -r '.display')"

target_display="$(
  $YABAI_BIN -m query --displays |
    jq -r --argjson current "$source_display" '
      [.[].index] | sort as $displays |
      if ($displays | length) < 2 then empty
      else $displays[((($displays | index($current)) + 1) % ($displays | length))]
      end
    '
)"
[[ -n "$target_display" ]] || exit 0

target_space="$(
  printf '%s\n' "$spaces_json" |
    jq -c --argjson display "$target_display" '.[] | select(.display == $display and ."is-visible" == true and ."is-native-fullscreen" == false)' |
    head -n 1
)"
[[ -n "$target_space" ]] || { printf 'Display %s has no visible user Space.\n' "$target_display" >&2; exit 1; }

target_index="$(printf '%s\n' "$target_space" | jq -r '.index')"
target_label="$(printf '%s\n' "$target_space" | jq -r '.label // empty')"
target_workspace="${target_label#ws-}"

identity_for_space() {
  printf '%s\n' "$1" | jq -r 'if .uuid == "" then "id:" + (.id | tostring) else "uuid:" + .uuid end'
}

source_identity="$(identity_for_space "$source_space")"
target_identity="$(identity_for_space "$target_space")"
temporary_label="yabai-swap-$$"

source_windows="$(
  $YABAI_BIN -m query --windows |
    jq -r --argjson space "$source_index" '.[] | select(.space == $space and ."can-move" == true and ."is-native-fullscreen" == false) | .id'
)"
target_windows="$(
  $YABAI_BIN -m query --windows |
    jq -r --argjson space "$target_index" '.[] | select(.space == $space and ."can-move" == true and ."is-native-fullscreen" == false) | .id'
)"

# Swapping labels and window contents emulates moving an AeroSpace workspace
# without requiring the privileged yabai scripting addition.
$YABAI_BIN -m space "$source_label" --label "$temporary_label"
$YABAI_BIN -m space "$target_index" --label "$source_label"
if [[ -n "$target_label" ]]; then
  $YABAI_BIN -m space "$temporary_label" --label "$target_label"
  source_destination="$target_label"
else
  source_destination="$temporary_label"
fi

while IFS= read -r window_id; do
  [[ -n "$window_id" ]] || continue
  $YABAI_BIN -m window "$window_id" --space "$source_label"
done <<<"$source_windows"

while IFS= read -r window_id; do
  [[ -n "$window_id" ]] || continue
  $YABAI_BIN -m window "$window_id" --space "$source_destination"
done <<<"$target_windows"

if [[ -z "$target_label" ]]; then
  $YABAI_BIN -m space "$temporary_label" --label ""
fi

[[ -f "$YABAI_WORKSPACE_STATE" ]] || { printf '%s\n' 'Workspace state is not initialized.' >&2; exit 1; }
state_tmp="$(mktemp "$YABAI_STATE_DIR/workspaces.XXXXXX")"
trap 'rm -f "$state_tmp"' EXIT

awk -F'|' \
  -v source_workspace="$source_workspace" \
  -v source_identity="$source_identity" \
  -v target_workspace="$target_workspace" \
  -v target_identity="$target_identity" '
    $1 == source_workspace { print source_workspace "|" target_identity; next }
    target_workspace != "" && $1 == target_workspace { print target_workspace "|" source_identity; next }
    { print }
  ' "$YABAI_WORKSPACE_STATE" >"$state_tmp"

mv "$state_tmp" "$YABAI_WORKSPACE_STATE"
trap - EXIT
"$script_dir/focus-space.sh" "$source_workspace"
