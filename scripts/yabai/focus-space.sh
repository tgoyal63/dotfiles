#!/usr/bin/env bash
set -euo pipefail

[[ $# -eq 1 ]] || exit 2
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck disable=SC1091
. "$script_dir/lib.sh"

target_label="$(workspace_label "$1")"
workspace_exists "$1" || { printf 'Unknown logical workspace: %s\n' "$1" >&2; exit 1; }

# Native Space transitions can temporarily reject another focus request. Serialize
# and verify them so rapid keyboard navigation is queued instead of dropped.
lock_dir="${TMPDIR:-/tmp}/yabai-space-focus-${UID}.lock"
lock_acquired=false
for _ in {1..150}; do
  if mkdir "$lock_dir" 2>/dev/null; then
    printf '%s\n' "$$" >"$lock_dir/pid"
    lock_acquired=true
    break
  fi

  if [[ -r "$lock_dir/pid" ]]; then
    lock_pid="$(cat "$lock_dir/pid" 2>/dev/null || true)"
    if [[ -n "$lock_pid" ]] && ! kill -0 "$lock_pid" 2>/dev/null; then
      rm -rf "$lock_dir"
      continue
    fi
  fi
  sleep 0.02
done

[[ "$lock_acquired" == true ]] || { printf '%s\n' 'Timed out waiting for the Space focus queue.' >&2; exit 1; }
trap 'rm -rf "$lock_dir"' EXIT

for _ in {1..4}; do
  current_label="$($YABAI_BIN -m query --spaces --space 2>/dev/null | jq -r '.label // empty' || true)"
  [[ "$current_label" == "$target_label" ]] && exit 0

  "$YABAI_BIN" -m space --focus "$target_label" >/dev/null 2>&1 || true
  for _ in {1..40}; do
    current_label="$($YABAI_BIN -m query --spaces --space 2>/dev/null | jq -r '.label // empty' || true)"
    [[ "$current_label" == "$target_label" ]] && exit 0
    sleep 0.03
  done
done

printf 'Unable to focus logical workspace %s.\n' "$1" >&2
exit 1
