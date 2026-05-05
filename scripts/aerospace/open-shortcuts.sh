#!/usr/bin/env sh
set -eu

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
shortcuts_file="$script_dir/../../SHORTCUTS.md"

if [ ! -f "$shortcuts_file" ]; then
  shortcuts_file="$HOME/projects/temp/dotfiles/SHORTCUTS.md"
fi

open -a TextEdit "$shortcuts_file"
