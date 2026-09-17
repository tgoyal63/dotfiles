#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck disable=SC1091
. "$script_dir/lib.sh"

"$YABAI_BIN" -m signal --remove route-new-window >/dev/null 2>&1 || true
"$YABAI_BIN" -m signal --add \
  label=route-new-window \
  event=window_created \
  action="$YABAI_CONFIG_DIR/scripts/route-window.sh \"\$YABAI_WINDOW_ID\""
