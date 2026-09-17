#!/usr/bin/env bash
set -euo pipefail

[[ $# -eq 1 ]] || exit 2

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck disable=SC1091
. "$script_dir/lib.sh"

window_json="$($YABAI_BIN -m query --windows --window "$1" 2>/dev/null || true)"
[[ -n "$window_json" ]] || exit 0

pid="$(printf '%s\n' "$window_json" | jq -r '.pid // empty')"
app_name_lower="$(printf '%s\n' "$window_json" | jq -r '.app // empty' | tr '[:upper:]' '[:lower:]')"
[[ -n "$pid" ]] || exit 0

bundle_id="$(bundle_id_for_pid "$pid")"
workspace="$(target_workspace_for_app "$bundle_id" "$app_name_lower")"

if workspace_exists "$workspace"; then
  if [[ "$(printf '%s\n' "$window_json" | jq -r '."is-floating" // false')" == "true" ]]; then
    "$YABAI_BIN" -m window "$1" --toggle float >/dev/null 2>&1 || true
  fi
  "$YABAI_BIN" -m window "$1" --space "$(workspace_label "$workspace")" >/dev/null 2>&1 || true
fi
