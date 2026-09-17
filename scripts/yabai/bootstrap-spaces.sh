#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck disable=SC1091
. "$script_dir/lib.sh"

mode="${1:---apply}"
case "$mode" in
  --apply|--initialize|--initialize-messaging|--create) ;;
  *)
    printf 'Usage: %s [--apply|--initialize|--initialize-messaging|--create]\n' "$0" >&2
    exit 2
    ;;
esac

spaces_json="$($YABAI_BIN -m query --spaces)"
workspace_count="$(printf '%s\n' "$WORKSPACE_ORDER" | wc -w | tr -d '[:space:]')"
space_count="$(printf '%s\n' "$spaces_json" | jq '[.[] | select(."is-native-fullscreen" == false)] | length')"

if [[ "$mode" == "--create" ]]; then
  display_indices=( $($YABAI_BIN -m query --displays | jq -r 'sort_by(.index) | .[].index') )
  display_count="${#display_indices[@]}"
  [[ "$display_count" -gt 0 ]] || { printf 'No displays reported by yabai.\n' >&2; exit 1; }

  while [[ "$space_count" -lt "$workspace_count" ]]; do
    target_display="${display_indices[$((space_count % display_count))]}"
    created=false
    for _ in {1..50}; do
      if "$YABAI_BIN" -m space --create "$target_display" >/dev/null 2>&1; then
        created=true
        break
      fi
      sleep 0.1
    done
    if [[ "$created" != true ]]; then
      printf '%s\n' 'Unable to create native Spaces. The scripting addition is not active.' >&2
      exit 1
    fi

    previous_space_count="$space_count"
    for _ in {1..100}; do
      spaces_json="$($YABAI_BIN -m query --spaces)"
      space_count="$(printf '%s\n' "$spaces_json" | jq '[.[] | select(."is-native-fullscreen" == false)] | length')"
      [[ "$space_count" -gt "$previous_space_count" ]] && break
      sleep 0.05
    done
    [[ "$space_count" -gt "$previous_space_count" ]] || { printf '%s\n' 'Timed out waiting for macOS to publish the created Space.' >&2; exit 1; }
  done
  mode="--initialize"
  spaces_json="$($YABAI_BIN -m query --spaces)"
fi

if [[ "$mode" == "--initialize" || "$mode" == "--initialize-messaging" ]]; then
  if [[ "$mode" == "--initialize-messaging" ]]; then
    required_space_count=3
    initialization_order="c 6 4"
  else
    required_space_count="$workspace_count"
    initialization_order="$WORKSPACE_ORDER"
  fi

  if [[ "$space_count" -lt "$required_space_count" ]]; then
    printf 'Need %s non-fullscreen Spaces; yabai currently reports %s.\n' "$required_space_count" "$space_count" >&2
    printf '%s\n' 'Create the missing Spaces in Mission Control, or enable the scripting addition and rerun with --create.' >&2
    exit 1
  fi

  mkdir -p "$YABAI_STATE_DIR"
  state_tmp="$(mktemp "$YABAI_STATE_DIR/workspaces.XXXXXX")"
  current_identities="${state_tmp}.current"
  identity_displays="${state_tmp}.displays"
  candidate_identities="${state_tmp}.candidates"
  preserved_mappings="${state_tmp}.preserved"
  trap 'rm -f "$state_tmp" "${state_tmp}.current" "${state_tmp}.displays" "${state_tmp}.candidates" "${state_tmp}.preserved"' EXIT

  printf '%s\n' "$spaces_json" |
    jq -r '[.[] | select(."is-native-fullscreen" == false)] | sort_by(.index) | .[] | if .uuid == "" then "id:" + (.id | tostring) else "uuid:" + .uuid end' \
    >"$current_identities"
  printf '%s\n' "$spaces_json" |
    jq -r '[.[] | select(."is-native-fullscreen" == false)] | sort_by(.display, .index) | .[] | [(if .uuid == "" then "id:" + (.id | tostring) else "uuid:" + .uuid end), (.display | tostring)] | join("|")' \
    >"$identity_displays"

  : >"$preserved_mappings"
  if [[ -f "$YABAI_WORKSPACE_STATE" ]]; then
    while IFS='|' read -r workspace identity; do
      [[ " $initialization_order " == *" $workspace "* ]] || continue
      grep -Fxq -- "$identity" "$current_identities" || continue
      awk -F'|' -v identity="$identity" '$2 == identity { found = 1 } END { exit !found }' "$preserved_mappings" && continue
      printf '%s|%s\n' "$workspace" "$identity" >>"$preserved_mappings"
    done <"$YABAI_WORKSPACE_STATE"
  fi

  messaging_display_in_use() {
    local candidate_display="$1"
    local mapped_workspace
    local mapped_identity
    local mapped_display

    while IFS='|' read -r mapped_workspace mapped_identity; do
      case "$mapped_workspace" in
        c|6|4) ;;
        *) continue ;;
      esac
      mapped_display="$(awk -F'|' -v identity="$mapped_identity" '$1 == identity { print $2; exit }' "$identity_displays")"
      [[ "$mapped_display" == "$candidate_display" ]] && return 0
    done <"$preserved_mappings"
    return 1
  }

  # Keep the three messaging roles on distinct displays on every fresh or
  # repaired initialization, regardless of macOS Space enumeration order.
  for workspace in c 6 4; do
    if awk -F'|' -v workspace="$workspace" '$1 == workspace { found = 1 } END { exit !found }' "$preserved_mappings"; then
      continue
    fi

    identity="$(
      while IFS='|' read -r candidate candidate_display; do
        awk -F'|' -v identity="$candidate" '$2 == identity { found = 1 } END { exit !found }' "$preserved_mappings" && continue
        messaging_display_in_use "$candidate_display" && continue
        printf '%s\n' "$candidate"
        break
      done <"$identity_displays"
    )"
    if [[ -z "$identity" ]]; then
      identity="$(
        while IFS= read -r candidate; do
          if ! awk -F'|' -v identity="$candidate" '$2 == identity { found = 1 } END { exit !found }' "$preserved_mappings"; then
            printf '%s\n' "$candidate"
            break
          fi
        done <"$current_identities"
      )"
    fi
    [[ -n "$identity" ]] || { printf 'Unable to reserve native Space for workspace %s.\n' "$workspace" >&2; exit 1; }
    printf '%s|%s\n' "$workspace" "$identity" >>"$preserved_mappings"
  done

  if [[ "$mode" == "--initialize-messaging" ]]; then
    {
      # Prefer one existing Space per display for Canary, WhatsApp, and Discord.
      printf '%s\n' "$spaces_json" |
        jq -r '[.[] | select(."is-native-fullscreen" == false)] | sort_by(.display, .index) | group_by(.display) | .[] | .[0] | if .uuid == "" then "id:" + (.id | tostring) else "uuid:" + .uuid end'
      cat "$current_identities"
    } | awk '!seen[$0]++' >"$candidate_identities"
  else
    cp "$current_identities" "$candidate_identities"
  fi

  for workspace in $initialization_order; do
    if awk -F'|' -v workspace="$workspace" '$1 == workspace { found = 1 } END { exit !found }' "$preserved_mappings"; then
      continue
    fi

    identity="$(
      while IFS= read -r candidate; do
        if ! awk -F'|' -v identity="$candidate" '$2 == identity { found = 1 } END { exit !found }' "$preserved_mappings"; then
          printf '%s\n' "$candidate"
          break
        fi
      done <"$candidate_identities"
    )"
    [[ -n "$identity" ]] || { printf 'Unable to assign native Space for workspace %s.\n' "$workspace" >&2; exit 1; }
    printf '%s|%s\n' "$workspace" "$identity" >>"$preserved_mappings"
  done

  for workspace in $initialization_order; do
    awk -F'|' -v workspace="$workspace" '$1 == workspace { print; exit }' "$preserved_mappings"
  done >"$state_tmp"

  mv "$state_tmp" "$YABAI_WORKSPACE_STATE"
  rm -f "$current_identities" "$identity_displays" "$candidate_identities" "$preserved_mappings"
  trap - EXIT
fi

if [[ ! -f "$YABAI_WORKSPACE_STATE" ]]; then
  printf '%s\n' 'Native Space labels are not initialized yet; run bootstrap-spaces.sh --initialize after creating the Spaces.' >&2
  exit 1
fi

apply_status=0
while IFS='|' read -r workspace identity; do
  [[ -n "$workspace" && -n "$identity" ]] || continue
  case "$identity" in
    uuid:*)
      space_index="$(printf '%s\n' "$spaces_json" | jq -r --arg uuid "${identity#uuid:}" '.[] | select(.uuid == $uuid) | .index' | head -n 1)"
      ;;
    id:*)
      space_index="$(printf '%s\n' "$spaces_json" | jq -r --argjson id "${identity#id:}" '.[] | select(.id == $id) | .index' | head -n 1)"
      ;;
    *)
      space_index="$(printf '%s\n' "$spaces_json" | jq -r --arg uuid "$identity" '.[] | select(.uuid == $uuid) | .index' | head -n 1)"
      ;;
  esac
  if [[ -n "$space_index" ]]; then
    "$YABAI_BIN" -m space "$space_index" --label "$(workspace_label "$workspace")"
  else
    printf 'Saved workspace %s no longer exists; rerun with --initialize.\n' "$workspace" >&2
    apply_status=1
  fi
done <"$YABAI_WORKSPACE_STATE"

exit "$apply_status"
