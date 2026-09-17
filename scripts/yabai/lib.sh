#!/usr/bin/env bash

YABAI_BIN="${YABAI_BIN:-/opt/homebrew/bin/yabai}"
YABAI_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/yabai"
YABAI_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/yabai"
YABAI_WORKSPACE_STATE="$YABAI_STATE_DIR/workspaces.tsv"

# shellcheck disable=SC1091
. "$YABAI_CONFIG_DIR/workspace-settings.sh"

workspace_label() {
  printf 'ws-%s\n' "$1"
}

workspace_exists() {
  local label
  label="$(workspace_label "$1")"
  "$YABAI_BIN" -m query --spaces | jq -e --arg label "$label" 'any(.[]; .label == $label)' >/dev/null
}

workspace_state_is_complete() {
  local expected_workspaces
  local actual_workspaces
  local row_count
  local unique_identity_count

  [[ -f "$YABAI_WORKSPACE_STATE" ]] || return 1

  expected_workspaces="$(printf '%s\n' $WORKSPACE_ORDER)"
  actual_workspaces="$(awk -F'|' 'NF == 2 && $1 != "" && $2 != "" { print $1 }' "$YABAI_WORKSPACE_STATE")"
  [[ "$actual_workspaces" == "$expected_workspaces" ]] || return 1

  row_count="$(awk -F'|' 'NF == 2 && $1 != "" && $2 != "" { count++ } END { print count + 0 }' "$YABAI_WORKSPACE_STATE")"
  unique_identity_count="$(awk -F'|' 'NF == 2 && $2 != "" { identities[$2] = 1 } END { for (identity in identities) count++; print count + 0 }' "$YABAI_WORKSPACE_STATE")"
  [[ "$row_count" -eq "$unique_identity_count" ]]
}

relative_workspace() {
  local current_workspace="$1"
  local direction="$2"
  local workspaces=( $WORKSPACE_ORDER )
  local workspace_count="${#workspaces[@]}"
  local index
  local target_index

  for ((index = 0; index < workspace_count; index++)); do
    [[ "${workspaces[$index]}" == "$current_workspace" ]] || continue
    if [[ "$direction" == "next" ]]; then
      target_index=$(((index + 1) % workspace_count))
    else
      target_index=$(((index - 1 + workspace_count) % workspace_count))
    fi
    printf '%s\n' "${workspaces[$target_index]}"
    return 0
  done

  printf '%s\n' "${workspaces[0]}"
}

bundle_id_for_pid() {
  lsappinfo info -only bundleid -app "$1" 2>/dev/null |
    sed -n 's/.*bundleID="\([^"]*\)".*/\1/p' |
    head -n 1
}
