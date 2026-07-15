#!/usr/bin/env sh
set -eu

script_path="$0"

while [ -L "$script_path" ]; do
  link_target="$(readlink "$script_path")"

  case "$link_target" in
    /*) script_path="$link_target" ;;
    *) script_path="$(dirname -- "$script_path")/$link_target" ;;
  esac
done

script_dir="$(CDPATH= cd -- "$(dirname -- "$script_path")" && pwd -P)"
shortcuts_file="$script_dir/../../SHORTCUTS.md"

if [ ! -f "$shortcuts_file" ]; then
  printf 'Could not find shortcut overview: %s\n' "$shortcuts_file" >&2
  exit 1
fi

open -a TextEdit "$shortcuts_file"
