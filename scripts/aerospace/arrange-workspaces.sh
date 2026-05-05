#!/usr/bin/env sh
set -eu

# Restore app roles and workspace-to-monitor layout without force-pinning.
# Workspaces can still be moved manually after this runs.
script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
. "$script_dir/workspace-settings.sh"

move_apps_to_workspaces() {
  windows_file="${TMPDIR:-/tmp}/aerospace-arrange-windows.$$"
  trap 'rm -f "$windows_file"' EXIT HUP INT TERM

  aerospace list-windows --monitor all --format '%{window-id}|%{app-bundle-id}|%{app-name}' >"$windows_file"

  while IFS='|' read -r window_id app_id app_name; do
    window_id="$(printf '%s' "$window_id" | tr -d '[:space:]')"
    app_id="$(printf '%s' "$app_id" | xargs)"
    app_name="$(printf '%s' "$app_name" | xargs)"
    app_name_lower="$(printf '%s' "$app_name" | tr '[:upper:]' '[:lower:]')"

    [ -n "$window_id" ] && [ -n "$app_id" ] || continue

    workspace="$(target_workspace_for_app "$app_id" "$app_name_lower")"

    if aerospace move-node-to-workspace --window-id "$window_id" "$workspace" >/dev/null 2>&1; then
      printf 'Moved %s to workspace %s\n' "$app_name" "$workspace"
    else
      printf 'Could not move %s to workspace %s\n' "$app_name" "$workspace" >&2
    fi
  done <"$windows_file"
}

move_workspace() {
  workspace="$1"
  monitor="$2"

  if ! aerospace move-workspace-to-monitor --workspace "$workspace" "$monitor" >/dev/null 2>&1; then
    printf 'Could not move workspace %s to %s\n' "$workspace" "$monitor" >&2
  fi
}

move_apps_to_workspaces

for workspace in $WORK_MONITOR_WORKSPACES; do
  move_workspace "$workspace" "$WORK_MONITOR"
done

for workspace in $SIDE_MONITOR_WORKSPACES; do
  move_workspace "$workspace" "$SIDE_MONITOR"
done

printf '%s\n' 'Workspace monitor layout restored.'
