#!/usr/bin/env sh
set -eu

# Restore app roles and workspace-to-monitor layout without force-pinning.
# Workspaces can still be moved manually after this runs.
work_monitor="AORUS FI27Q"
side_monitor="Built-in Retina Display"

target_workspace() {
  app_id="$1"
  app_name_lower="$2"

  case "$app_id" in
    com.mitchellh.ghostty|com.microsoft.VSCode)
      printf '%s\n' 1
      ;;
    app.zen-browser.zen)
      printf '%s\n' 2
      ;;
    com.openai.chat|com.openai.codex)
      printf '%s\n' 3
      ;;
    com.hnc.Discord|net.whatsapp.WhatsApp|ru.keepcoder.Telegram|com.apple.mail)
      printf '%s\n' 4
      ;;
    com.spotify.client)
      printf '%s\n' 5
      ;;
    com.obsproject.obs-studio)
      printf '%s\n' o
      ;;
    com.apple.Notes|com.apple.iCal)
      printf '%s\n' 7
      ;;
    com.google.Chrome|com.brave.Browser)
      printf '%s\n' 8
      ;;
    *)
      case "$app_name_lower" in
        *audacity*) printf '%s\n' 6 ;;
        *obsidian*|*notion*|*todoist*|*things*) printf '%s\n' 7 ;;
        *docker*|*orbstack*|*postman*|*insomnia*) printf '%s\n' 9 ;;
        *) printf '%s\n' 0 ;;
      esac
      ;;
  esac
}

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

    workspace="$(target_workspace "$app_id" "$app_name_lower")"

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

# Main work display.
move_workspace 1 "$work_monitor"
move_workspace 2 "$work_monitor"
move_workspace 3 "$work_monitor"
move_workspace 7 "$work_monitor"
move_workspace 8 "$work_monitor"
move_workspace 9 "$work_monitor"

# Side/private display.
move_workspace 4 "$side_monitor"
move_workspace 5 "$side_monitor"
move_workspace 6 "$side_monitor"
move_workspace 0 "$side_monitor"
move_workspace o "$side_monitor"

printf '%s\n' 'Workspace monitor layout restored.'
