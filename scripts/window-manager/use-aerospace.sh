#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
aerospace_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/aerospace"

/opt/homebrew/bin/skhd --stop-service >/dev/null 2>&1 || true
/opt/homebrew/bin/skhd --uninstall-service >/dev/null 2>&1 || true
/opt/homebrew/bin/yabai --stop-service >/dev/null 2>&1 || true
/opt/homebrew/bin/yabai --uninstall-service >/dev/null 2>&1 || true
mkdir -p "$aerospace_config_dir"
ln -sfn "$repo_dir/aerospace.toml" "$aerospace_config_dir/aerospace.toml"
rm -f "$aerospace_config_dir/aerospace.yabai-disabled.toml"
open -a AeroSpace
sleep 1
aerospace reload-config >/dev/null 2>&1 || true
aerospace enable on >/dev/null 2>&1 || true

"$repo_dir/scripts/macos/fix-mission-control.sh"

printf '%s\n' 'AeroSpace is active. Log out and back in if the Mission Control profile changed.'
