#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/link-configs.sh [--dry-run]

Create or refresh this repository's dotfile symlinks. Existing regular files
and directories are never overwritten.
EOF
}

dry_run=false

case "${1:-}" in
  "") ;;
  --dry-run) dry_run=true ;;
  -h|--help)
    usage
    exit 0
    ;;
  *)
    printf 'Unknown option: %s\n\n' "$1" >&2
    usage >&2
    exit 1
    ;;
esac

if [[ $# -gt 1 ]]; then
  usage >&2
  exit 1
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
repo_dir="$(cd -- "$script_dir/.." && pwd -P)"
failures=0

ensure_directory() {
  local directory="$1"

  if [[ -d "$directory" ]]; then
    return
  fi

  if [[ -e "$directory" || -L "$directory" ]]; then
    printf 'Refusing to replace non-directory path: %s\n' "$directory" >&2
    failures=$((failures + 1))
    return 1
  fi

  if $dry_run; then
    printf 'CREATE   %s\n' "$directory"
  else
    mkdir -p -- "$directory"
    printf 'CREATED  %s\n' "$directory"
  fi
}

link_path() {
  local source_path="$1"
  local target_path="$2"
  local current_target

  if [[ ! -e "$source_path" ]]; then
    printf 'Missing repository path: %s\n' "$source_path" >&2
    failures=$((failures + 1))
    return
  fi

  if ! ensure_directory "$(dirname -- "$target_path")"; then
    return
  fi

  if [[ -L "$target_path" ]]; then
    current_target="$(readlink "$target_path")"

    if [[ "$current_target" == "$source_path" ]]; then
      printf 'OK       %s -> %s\n' "$target_path" "$source_path"
      return
    fi

    if $dry_run; then
      printf 'RELINK   %s -> %s\n' "$target_path" "$source_path"
    else
      ln -sfn -- "$source_path" "$target_path"
      printf 'RELINKED %s -> %s\n' "$target_path" "$source_path"
    fi
    return
  fi

  if [[ -e "$target_path" ]]; then
    printf 'Refusing to overwrite existing path: %s\n' "$target_path" >&2
    failures=$((failures + 1))
    return
  fi

  if $dry_run; then
    printf 'LINK     %s -> %s\n' "$target_path" "$source_path"
  else
    ln -s -- "$source_path" "$target_path"
    printf 'LINKED   %s -> %s\n' "$target_path" "$source_path"
  fi
}

link_path "$repo_dir/.zshrc" "$HOME/.zshrc"
link_path "$repo_dir/aerospace.toml" "$HOME/.config/aerospace/aerospace.toml"
link_path "$repo_dir/ghostty.toml" "$HOME/.config/ghostty/config"
link_path "$repo_dir/starship.toml" "$HOME/.config/starship.toml"
link_path "$repo_dir/finicky.ts" "$HOME/.finicky.ts"

aerospace_scripts_target="$HOME/.config/aerospace/scripts"

if [[ -L "$aerospace_scripts_target" || ! -e "$aerospace_scripts_target" ]]; then
  link_path "$repo_dir/scripts/aerospace" "$aerospace_scripts_target"
elif [[ -d "$aerospace_scripts_target" ]]; then
  link_path "$repo_dir/scripts/aerospace/arrange-workspaces.sh" "$aerospace_scripts_target/arrange-workspaces.sh"
  link_path "$repo_dir/scripts/aerospace/open-shortcuts.sh" "$aerospace_scripts_target/open-shortcuts.sh"
  link_path "$repo_dir/scripts/aerospace/privacy-screen-share.sh" "$aerospace_scripts_target/privacy-screen-share.sh"
  link_path "$repo_dir/scripts/aerospace/workspace-settings.sh" "$aerospace_scripts_target/workspace-settings.sh"
  link_path "$repo_dir/scripts/aerospace/spotify" "$aerospace_scripts_target/spotify"
else
  printf 'Refusing to replace non-directory path: %s\n' "$aerospace_scripts_target" >&2
  failures=$((failures + 1))
fi

if [[ "$failures" -gt 0 ]]; then
  printf '\nLinking stopped with %d conflict(s). Move or back up those paths and try again.\n' "$failures" >&2
  exit 1
fi

if $dry_run; then
  printf '\nDry run complete; no links were changed.\n'
else
  printf '\nDotfile links are ready.\n'
fi
