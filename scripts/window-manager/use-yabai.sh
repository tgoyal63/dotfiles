#!/usr/bin/env bash
set -euo pipefail

YABAI_BIN="/opt/homebrew/bin/yabai"
SKHD_BIN="/opt/homebrew/bin/skhd"
YABAI_READY="${XDG_STATE_HOME:-$HOME/.local/state}/yabai/ready"
YABAI_STARTUP_LOG="/tmp/yabai-startup_${USER}.log"
YABAI_DAEMON_LOG="/tmp/yabai_${USER}.err.log"
repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
aerospace_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/aerospace"
aerospace_active_config="$aerospace_config_dir/aerospace.toml"
aerospace_disabled_config="$aerospace_config_dir/aerospace.yabai-disabled.toml"

[[ -x "$YABAI_BIN" ]] || { printf '%s\n' 'yabai is not installed.' >&2; exit 1; }
[[ -x "$SKHD_BIN" ]] || { printf '%s\n' 'skhd is not installed.' >&2; exit 1; }

if [[ "$(defaults read com.apple.spaces spans-displays 2>/dev/null || printf 1)" != "0" ]]; then
  printf '%s\n' 'Displays have separate Spaces is not active. Run configure-yabai-spaces.sh, log out, and try again.' >&2
  exit 1
fi

if [[ ! -d /Library/ScriptingAdditions/yabai.osax ]]; then
  printf '%s\n' 'The yabai scripting addition is not installed. Complete the documented Recovery and enable-scripting-addition.sh steps first.' >&2
  exit 1
fi

if ! sudo -n "$YABAI_BIN" --load-sa >/dev/null 2>&1; then
  printf '%s\n' 'The scripting addition cannot be loaded non-interactively. Re-run enable-scripting-addition.sh for the currently installed yabai binary.' >&2
  exit 1
fi

rollback() {
  "$SKHD_BIN" --stop-service >/dev/null 2>&1 || true
  "$SKHD_BIN" --uninstall-service >/dev/null 2>&1 || true
  "$YABAI_BIN" --stop-service >/dev/null 2>&1 || true
  "$YABAI_BIN" --uninstall-service >/dev/null 2>&1 || true
  ln -sfn "$repo_dir/aerospace.toml" "$aerospace_active_config"
  rm -f "$aerospace_disabled_config"
  open -a AeroSpace
  sleep 1
  aerospace reload-config >/dev/null 2>&1 || true
  aerospace enable on >/dev/null 2>&1 || true
}

rm -f "$YABAI_READY"

# Reload once with start-at-login disabled so AeroSpace unregisters its login
# item. Keep the normal config untouched for an atomic rollback.
mkdir -p "$aerospace_config_dir"
disabled_tmp="$(mktemp "$aerospace_config_dir/aerospace-disabled.XXXXXX")"
awk '{
  if ($0 == "start-at-login = true") print "start-at-login = false"
  else print
}' "$repo_dir/aerospace.toml" >"$disabled_tmp"
mv "$disabled_tmp" "$aerospace_disabled_config"
ln -sfn "$aerospace_disabled_config" "$aerospace_active_config"
aerospace reload-config >/dev/null 2>&1 || true
aerospace enable off >/dev/null 2>&1 || true
osascript -e 'tell application "AeroSpace" to quit' >/dev/null 2>&1 || true

service_path="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
if ! env PATH="$service_path" "$YABAI_BIN" --start-service; then
  rollback
  exit 1
fi

for _ in {1..600}; do
  [[ -f "$YABAI_READY" ]] && break
  sleep 0.1
done

if [[ ! -f "$YABAI_READY" ]]; then
  printf '%s\n' 'yabai did not establish all logical workspaces; restoring AeroSpace.' >&2
  tail -n 40 "$YABAI_STARTUP_LOG" >&2 2>/dev/null || true
  tail -n 40 "$YABAI_DAEMON_LOG" >&2 2>/dev/null || true
  rollback
  exit 1
fi

if ! env PATH="$service_path" "$SKHD_BIN" --start-service; then
  rollback
  exit 1
fi

printf '%s\n' 'yabai is active with all logical workspaces ready.'
