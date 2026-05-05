#!/usr/bin/env bash
set -eu

# Move sensitive apps away from the focused monitor before/during screen share.
# Focus the shared monitor, then run this script.
is_sensitive_app() {
  app_id="$1"

  case "$app_id" in
    com.hnc.Discord|net.whatsapp.WhatsApp|com.spotify.client|com.obsproject.obs-studio)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

moved=0
windows_file="${TMPDIR:-/tmp}/aerospace-privacy-windows.$$"
trap 'rm -f "$windows_file"' EXIT HUP INT TERM

aerospace list-windows --monitor focused --format '%{window-id}|%{app-bundle-id}|%{app-name}' >"$windows_file"

while IFS='|' read -r window_id app_id app_name; do
  window_id="$(printf '%s' "$window_id" | tr -d '[:space:]')"
  app_id="$(printf '%s' "$app_id" | xargs)"
  app_name="$(printf '%s' "$app_name" | xargs)"

  [ -n "$window_id" ] && [ -n "$app_id" ] || continue

  if is_sensitive_app "$app_id"; then
    aerospace move-node-to-monitor --window-id "$window_id" --wrap-around next
    printf 'Moved %s away from the focused monitor\n' "$app_name"
    moved=$((moved + 1))
  fi
done <"$windows_file"

if [ "$moved" -eq 0 ]; then
  printf '%s\n' 'No sensitive windows found on the focused monitor.'
fi
