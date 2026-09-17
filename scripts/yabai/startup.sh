#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck disable=SC1091
. "$script_dir/lib.sh"

ready_file="$YABAI_STATE_DIR/ready"
mkdir -p "$YABAI_STATE_DIR"
rm -f "$ready_file"

workspace_count="$(printf '%s\n' "$WORKSPACE_ORDER" | wc -w | tr -d '[:space:]')"

# launchd can start yabai before WindowManager has published its full inventory.
stable_count=0
previous_signature=""
for _ in {1..120}; do
  if spaces_json="$($YABAI_BIN -m query --spaces 2>/dev/null)"; then
    signature="$(printf '%s\n' "$spaces_json" | jq -r '[.[] | select(."is-native-fullscreen" == false) | (.uuid + ":" + (.id | tostring))] | sort | join(",")')"
    if [[ -n "$signature" && "$signature" == "$previous_signature" ]]; then
      stable_count=$((stable_count + 1))
      [[ "$stable_count" -ge 5 ]] && break
    else
      stable_count=0
      previous_signature="$signature"
    fi
  fi
  sleep 0.1
done

[[ "$stable_count" -ge 5 ]] || { printf '%s\n' 'macOS Space inventory did not stabilize.' >&2; exit 1; }

space_count="$(printf '%s\n' "$spaces_json" | jq '[.[] | select(."is-native-fullscreen" == false)] | length')"

if [[ "$space_count" -lt "$workspace_count" ]]; then
  [[ -d /Library/ScriptingAdditions/yabai.osax ]] || {
    printf 'Need %s native Spaces, but macOS reports %s and the scripting addition is unavailable.\n' "$workspace_count" "$space_count" >&2
    exit 1
  }
  "$script_dir/bootstrap-spaces.sh" --create
elif ! workspace_state_is_complete; then
  "$script_dir/bootstrap-spaces.sh" --initialize
elif ! "$script_dir/bootstrap-spaces.sh" --apply; then
  "$script_dir/bootstrap-spaces.sh" --initialize
fi

label_count="$($YABAI_BIN -m query --spaces | jq '[.[] | select(.label | startswith("ws-"))] | length')"
[[ "$label_count" -eq "$workspace_count" ]] || {
  printf 'Expected %s labeled workspaces after startup; found %s.\n' "$workspace_count" "$label_count" >&2
  exit 1
}

"$script_dir/register-routes.sh"
"$script_dir/arrange-workspaces.sh"

if [[ "${YABAI_START_APPS:-1}" == "1" ]]; then
  open -a Discord
  open -a Ghostty
  open -a Zen
  open -a "Visual Studio Code"
fi

printf '%s\n' "$(date +%s)" >"$ready_file"
