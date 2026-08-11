#!/usr/bin/env bash
set -euo pipefail

kiro_cli_path=''
for candidate in /opt/homebrew/bin/kiro-cli /usr/local/bin/kiro-cli; do
  if [[ -x "$candidate" ]]; then
    kiro_cli_path="$candidate"
    break
  fi
done

if [[ -z "$kiro_cli_path" ]]; then
  kiro_cli_path="$(command -v kiro-cli 2>/dev/null || true)"
fi

if [[ -z "$kiro_cli_path" || ! -x "$kiro_cli_path" ]]; then
  printf 'Kiro CLI is unavailable. Install the dev app group first.\n' >&2
  exit 1
fi

kiro_term_path='/Applications/Kiro CLI.app/Contents/MacOS/kiro-cli-term'
if [[ ! -x "$kiro_term_path" ]]; then
  printf 'Kiro CLI terminal helper is unavailable: %s\n' "$kiro_term_path" >&2
  exit 1
fi

local_bin="$HOME/.local/bin"
mkdir -p -- "$local_bin"

link_binary() {
  local source_path="$1"
  local target_path="$2"
  local current_target

  if [[ -L "$target_path" ]]; then
    current_target="$(readlink "$target_path")"
    if [[ "$current_target" == "$source_path" ]]; then
      printf 'OK       %s -> %s\n' "$target_path" "$source_path"
      return
    fi

    printf 'Refusing to replace existing symlink: %s -> %s\n' "$target_path" "$current_target" >&2
    exit 1
  fi

  if [[ -e "$target_path" ]]; then
    printf 'Refusing to replace existing path: %s\n' "$target_path" >&2
    exit 1
  fi

  ln -s -- "$source_path" "$target_path"
  printf 'LINKED   %s -> %s\n' "$target_path" "$source_path"
}

link_binary "$kiro_cli_path" "$local_bin/kiro-cli"
link_binary "$kiro_term_path" "$local_bin/kiro-cli-term"

"$local_bin/kiro-cli" integrations install dotfiles zsh
printf '\nKiro CLI Zsh integration is ready. Restart the terminal to activate it.\n'
