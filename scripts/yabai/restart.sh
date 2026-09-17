#!/usr/bin/env bash
set -euo pipefail

YABAI_BIN="${YABAI_BIN:-/opt/homebrew/bin/yabai}"
SKHD_BIN="${SKHD_BIN:-/opt/homebrew/bin/skhd}"
ready_file="${XDG_STATE_HOME:-$HOME/.local/state}/yabai/ready"

rm -f "$ready_file"
"$YABAI_BIN" --restart-service

for _ in {1..600}; do
  [[ -f "$ready_file" ]] && break
  sleep 0.1
done

[[ -f "$ready_file" ]] || { printf '%s\n' 'yabai did not become ready after restart.' >&2; exit 1; }
"$SKHD_BIN" --reload
