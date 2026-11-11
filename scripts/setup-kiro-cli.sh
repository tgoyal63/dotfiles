#!/usr/bin/env bash
set -euo pipefail

# Kiro 3.2 retains init for existing hooks, but no longer provides the old
# dotfiles installer. This script checks compatibility without changing files.
kiro_cli_path="$(command -v kiro-cli 2>/dev/null || true)"

if [[ -z "$kiro_cli_path" || ! -x "$kiro_cli_path" ]]; then
  printf 'Kiro CLI is unavailable. Install the dev app group first.\n' >&2
  exit 1
fi

if ! "$kiro_cli_path" init --help >/dev/null 2>&1; then
  printf 'This Kiro CLI does not expose init. Existing shell files were left untouched.\n' >&2
  exit 1
fi

support_dir="$HOME/Library/Application Support/kiro-cli/shell"
for phase in pre post; do
  hook="$support_dir/zshrc.$phase.zsh"
  if [[ -e "$hook" || -L "$hook" ]]; then
    if [[ ! -f "$hook" || ! -r "$hook" ]]; then
      printf 'Unreadable Kiro shell hook: %s\n' "$hook" >&2
      exit 1
    fi
    zsh -n "$hook"
    if grep -Fq '~/.local/bin/kiro-cli' "$hook" && [[ ! -x "$HOME/.local/bin/kiro-cli" ]]; then
      printf 'Existing Kiro hook references an unavailable executable: %s/.local/bin/kiro-cli\n' "$HOME" >&2
      exit 1
    fi
    printf 'OK       existing %s hook syntax\n' "$phase"
  else
    printf 'INFO     no legacy %s hook; Kiro 3.2 does not install these files\n' "$phase"
  fi

  if ! init_output="$("$kiro_cli_path" init zsh "$phase" --rcfile zshrc)"; then
    printf 'Kiro CLI init failed for %s; existing shell files were left untouched.\n' "$phase" >&2
    exit 1
  fi
  # Parse generated shell code; do not evaluate it or touch the live shell.
  printf '%s\n' "$init_output" | zsh -n
  printf 'OK       Kiro CLI init zsh %s\n' "$phase"
done

if router_status="$("$kiro_cli_path" integrations status kiro-command-router 2>&1)"; then
  printf 'INFO     optional command router: %s\n' "$router_status"
else
  printf 'INFO     optional command router status unavailable: %s\n' "$router_status"
fi

printf '\nCompatibility check only; no files, links, or integrations were installed.\n'
printf 'Legacy autocomplete is not provided by these init compatibility calls.\n'
