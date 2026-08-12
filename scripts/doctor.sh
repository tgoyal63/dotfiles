#!/usr/bin/env bash
set -uo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
repo_dir="$(cd -- "$script_dir/.." && pwd -P)"
checks=0
failures=0
warnings=0
secret_shape_pattern='(sk-[A-Za-z0-9_-]{20,}|github_pat_[A-Za-z0-9_]{20,}|gh[pousr]_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9-]{20,}|[sr]k_live_[A-Za-z0-9]{20,})'

pass() {
  checks=$((checks + 1))
  printf 'PASS  %s\n' "$1"
}

fail() {
  checks=$((checks + 1))
  failures=$((failures + 1))
  printf 'FAIL  %s\n' "$1" >&2
}

warn() {
  checks=$((checks + 1))
  warnings=$((warnings + 1))
  printf 'WARN  %s\n' "$1"
}

check_command() {
  if command -v "$1" >/dev/null 2>&1; then
    pass "command: $1"
  else
    fail "command missing: $1"
  fi
}

check_app() {
  if [[ -d "$1" ]]; then
    pass "app: ${1##*/}"
  else
    fail "app missing: ${1##*/}"
  fi
}

check_link() {
  local source_path="$1"
  local target_path="$2"
  local current_target

  current_target="$(readlink "$target_path" 2>/dev/null || true)"
  if [[ "$current_target" == "$source_path" ]]; then
    pass "link: $target_path"
  else
    fail "link drift: $target_path"
  fi
}

printf 'Dotfiles doctor\n\n'

for command_name in brew git zsh starship fzf zoxide atuin fnm bun python3.13 memo remindctl gh codexbar obsidian kiro-cli docker orbctl code; do
  check_command "$command_name"
done

for app_path in \
  /Applications/AeroSpace.app \
  /Applications/Finicky.app \
  /Applications/Ghostty.app \
  /Applications/Obsidian.app \
  /Applications/OrbStack.app \
  '/Applications/Visual Studio Code.app'; do
  check_app "$app_path"
done

check_link "$repo_dir/.zshrc" "$HOME/.zshrc"
check_link "$repo_dir/aerospace.toml" "$HOME/.config/aerospace/aerospace.toml"
check_link "$repo_dir/atuin.toml" "$HOME/.config/atuin/config.toml"
check_link "$repo_dir/finicky.ts" "$HOME/.finicky.ts"
check_link "$repo_dir/ghostty.toml" "$HOME/.config/ghostty/config"
check_link "$repo_dir/starship.toml" "$HOME/.config/starship.toml"
check_link "$repo_dir/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"

if [[ "$(orbctl status 2>/dev/null || true)" == "Running" ]]; then
  pass 'OrbStack backend'
else
  warn 'OrbStack backend is stopped'
fi

if docker info >/dev/null 2>&1; then
  pass 'Docker engine'
else
  warn 'Docker engine is unavailable'
fi

if [[ ! -d /Applications/Docker.app ]]; then
  pass 'Docker Desktop is absent'
else
  warn 'Docker Desktop is still installed'
fi

if ! command -v gemini >/dev/null 2>&1; then
  pass 'Gemini CLI is absent'
else
  warn 'Gemini CLI is still installed'
fi

reminders_status="$(remindctl status --plain --no-color --no-input 2>/dev/null || true)"
case "$reminders_status" in
  authorized|full-access) pass 'Apple Reminders access' ;;
  not-determined) warn 'Apple Reminders access is not configured (run: remind authorize)' ;;
  *) warn "Apple Reminders access: ${reminders_status:-unavailable}" ;;
esac

if atuin_history="$(atuin history list --format '{command}' 2>/dev/null)"; then
  if [[ -n "$atuin_history" ]]; then
    atuin_history_count="$(printf '%s\n' "$atuin_history" | wc -l | tr -d '[:space:]')"
  else
    atuin_history_count=0
  fi

  if [[ "$atuin_history_count" -gt 0 ]]; then
    pass "Atuin history: $atuin_history_count command(s)"
  else
    warn 'Atuin history is empty (run: atuin import zsh)'
  fi
else
  warn 'Atuin database is unavailable'
fi

if gh auth status >/dev/null 2>&1; then
  pass 'GitHub CLI authentication'
else
  warn 'GitHub CLI authentication is required (run: gh auth login)'
fi

if HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --no-upgrade --file "$repo_dir/Brewfile" >/dev/null 2>&1; then
  pass 'Homebrew bundle is installed'
else
  warn 'Homebrew bundle has missing entries (run: scripts/install-brew-apps.sh)'
fi

if grep -ERIq --exclude-dir=.git "$secret_shape_pattern" "$repo_dir" "$HOME/Library/Application Support/Code/User/settings.json" 2>/dev/null; then
  fail 'managed dotfiles contain a credential-shaped value'
else
  pass 'managed dotfiles contain no credential-shaped values'
fi

if "$repo_dir/scripts/check-config.sh" >/dev/null; then
  pass 'repository config validation'
else
  fail 'repository config validation'
fi

printf '\n%d checks, %d failure(s), %d warning(s)\n' "$checks" "$failures" "$warnings"
[[ "$failures" -eq 0 ]]
