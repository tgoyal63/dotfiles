#!/usr/bin/env bash
set -euo pipefail

YABAI_BIN="${YABAI_BIN:-/opt/homebrew/bin/yabai}"

focused_id="$("$YABAI_BIN" -m query --windows --window | jq -r '.id')"
"$YABAI_BIN" -m window "$focused_id" --display next
"$YABAI_BIN" -m window --focus "$focused_id" >/dev/null 2>&1 || true
