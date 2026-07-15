#!/usr/bin/env bash
set -uo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
repo_dir="$(cd -- "$script_dir/.." && pwd -P)"
checks=0
failures=0
skipped=0

pass() {
  checks=$((checks + 1))
  printf 'PASS  %s\n' "$1"
}

fail() {
  checks=$((checks + 1))
  failures=$((failures + 1))
  printf 'FAIL  %s\n' "$1" >&2

  if [[ -n "${2:-}" ]]; then
    printf '%s\n' "$2" | sed 's/^/      /' >&2
  fi
}

skip() {
  skipped=$((skipped + 1))
  printf 'SKIP  %s\n' "$1"
}

run_check() {
  local label="$1"
  local output
  shift

  if output="$("$@" 2>&1)"; then
    pass "$label"
  else
    fail "$label" "$output"
  fi
}

validate_script_syntax() {
  local file
  local interpreter
  local status=0

  while IFS= read -r file; do
    case "$(head -n 1 "$file")" in
      *bash) interpreter=bash ;;
      *) interpreter=sh ;;
    esac

    "$interpreter" -n "$file" || status=1
  done < <(find "$repo_dir/scripts" -type f -name '*.sh' -print | sort)

  return "$status"
}

validate_script_permissions() {
  local file
  local status=0

  while IFS= read -r file; do
    if [[ ! -x "$file" ]]; then
      printf 'Not executable: %s\n' "${file#"$repo_dir/"}" >&2
      status=1
    fi
  done < <(find "$repo_dir/scripts" -type f -name '*.sh' -print | sort)

  return "$status"
}

extract_aerospace_routes() {
  awk '
    /^\[\[on-window-detected\]\]$/ {
      condition_type = ""
      pattern = ""
      workspace = ""
      next
    }
    /^if\.app-id = "/ {
      condition_type = "app-id"
      pattern = $0
      sub(/^if\.app-id = "/, "", pattern)
      sub(/"$/, "", pattern)
      next
    }
    /^if\.app-name-regex-substring = "/ {
      condition_type = "app-name-regex-substring"
      pattern = $0
      sub(/^if\.app-name-regex-substring = "/, "", pattern)
      sub(/"$/, "", pattern)
      next
    }
    /^run = "move-node-to-workspace / {
      workspace = $0
      sub(/^run = "move-node-to-workspace /, "", workspace)
      sub(/"$/, "", workspace)
      if (condition_type != "" && pattern != "") {
        print condition_type "|" pattern "|" workspace
      }
    }
  ' "$repo_dir/aerospace.toml"
}

validate_workspace_routes() {
  local expected_routes
  local actual_routes
  local app_id
  local app_name_substring
  local expected_workspace

  # shellcheck disable=SC1091
  . "$repo_dir/scripts/aerospace/workspace-settings.sh"

  expected_routes="$({
    printf '%s\n' "$APP_ID_WORKSPACE_RULES" | sed '/^$/d; s/^/app-id|/'
    printf '%s\n' "$APP_NAME_WORKSPACE_RULES" | sed '/^$/d; s/^/app-name-regex-substring|/'
  } | sort)"
  actual_routes="$(extract_aerospace_routes | sort)"

  if [[ "$expected_routes" != "$actual_routes" ]]; then
    diff -u <(printf '%s\n' "$expected_routes") <(printf '%s\n' "$actual_routes") || true
    return 1
  fi

  while IFS='|' read -r app_id expected_workspace; do
    if [[ "$(target_workspace_for_app "$app_id" '')" != "$expected_workspace" ]]; then
      printf 'Incorrect helper route for app id: %s\n' "$app_id" >&2
      return 1
    fi
  done <<<"$APP_ID_WORKSPACE_RULES"

  while IFS='|' read -r app_name_substring expected_workspace; do
    if [[ "$(target_workspace_for_app '' "test-$app_name_substring-window")" != "$expected_workspace" ]]; then
      printf 'Incorrect helper route for app name: %s\n' "$app_name_substring" >&2
      return 1
    fi
  done <<<"$APP_NAME_WORKSPACE_RULES"
}

validate_documentation() {
  local expected_row='| `3` | AI | ChatGPT, Codex |'

  grep -Fqx "$expected_row" "$repo_dir/README.md" &&
    grep -Fqx "$expected_row" "$repo_dir/SHORTCUTS.md" &&
    grep -Fq 'scripts/link-configs.sh' "$repo_dir/README.md" &&
    grep -Fq 'scripts/check-config.sh' "$repo_dir/README.md"
}

run_check 'zsh syntax' zsh -n "$repo_dir/.zshrc" "$repo_dir"/zsh/*.zsh
run_check 'shell script syntax' validate_script_syntax
run_check 'shell script executable permissions' validate_script_permissions
run_check 'workspace routing stays synchronized' validate_workspace_routes
run_check 'key documentation stays synchronized' validate_documentation
run_check 'clean whitespace' git -C "$repo_dir" diff --check

tracked_ignored_files=''
while IFS= read -r ignored_file; do
  if [[ -n "$ignored_file" && -e "$repo_dir/$ignored_file" ]]; then
    tracked_ignored_files+="${tracked_ignored_files:+$'\n'}$ignored_file"
  fi
done < <(git -C "$repo_dir" ls-files -ci --exclude-standard)

if [[ -n "$tracked_ignored_files" ]]; then
  fail 'ignored files are not present and tracked' "$tracked_ignored_files"
else
  pass 'ignored files are not present and tracked'
fi

if command -v node >/dev/null 2>&1 && node --help 2>&1 | grep -q -- '--experimental-strip-types'; then
  run_check 'Finicky TypeScript syntax' node --experimental-strip-types --check "$repo_dir/finicky.ts"
else
  skip 'Finicky TypeScript syntax (this Node version cannot check TypeScript)'
fi

ghostty_bin="$(command -v ghostty 2>/dev/null || true)"
if [[ -z "$ghostty_bin" && -x /Applications/Ghostty.app/Contents/MacOS/ghostty ]]; then
  ghostty_bin=/Applications/Ghostty.app/Contents/MacOS/ghostty
fi

if [[ -n "$ghostty_bin" ]]; then
  run_check 'Ghostty config' "$ghostty_bin" +validate-config --config-file="$repo_dir/ghostty.toml"
else
  skip 'Ghostty config (Ghostty is unavailable)'
fi

if command -v starship >/dev/null 2>&1; then
  run_check 'Starship config' env TERM=xterm-256color STARSHIP_CONFIG="$repo_dir/starship.toml" starship prompt
else
  skip 'Starship config (Starship is unavailable)'
fi

if command -v aerospace >/dev/null 2>&1; then
  active_aerospace_config="$(aerospace config --config-path 2>/dev/null || true)"

  if [[ -L "$active_aerospace_config" ]]; then
    active_aerospace_config="$(readlink "$active_aerospace_config")"
  fi

  if [[ "$active_aerospace_config" == "$repo_dir/aerospace.toml" ]]; then
    run_check 'AeroSpace config reload' aerospace reload-config
  else
    skip 'AeroSpace config reload (this repo is not the active config)'
  fi
else
  skip 'AeroSpace config reload (AeroSpace is unavailable)'
fi

printf '\n%d checks, %d failure(s), %d skipped.\n' "$checks" "$failures" "$skipped"

if [[ "$failures" -gt 0 ]]; then
  exit 1
fi
