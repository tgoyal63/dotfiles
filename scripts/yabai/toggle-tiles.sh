#!/usr/bin/env bash
set -euo pipefail

YABAI_BIN="${YABAI_BIN:-/opt/homebrew/bin/yabai}"

"$YABAI_BIN" -m space --layout bsp
"$YABAI_BIN" -m space --rotate 90 >/dev/null 2>&1 || true
