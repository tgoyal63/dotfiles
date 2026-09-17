#!/usr/bin/env bash
set -euo pipefail

[[ $# -eq 1 ]] || exit 2
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck disable=SC1091
. "$script_dir/lib.sh"

"$YABAI_BIN" -m window --space "$(workspace_label "$1")"
