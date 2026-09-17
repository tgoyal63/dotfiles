#!/usr/bin/env bash
set -euo pipefail

[[ $# -eq 2 ]] || exit 2
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck disable=SC1091
. "$script_dir/lib.sh"

"$script_dir/focus-space.sh" "$1" >/dev/null 2>&1 || true
open -a "$2"
