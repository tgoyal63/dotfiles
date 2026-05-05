#!/usr/bin/env sh
set -eu

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
shortcuts_file="$script_dir/../../shortcuts.html"

if [ ! -f "$shortcuts_file" ]; then
  shortcuts_file="$HOME/projects/temp/dotfiles/shortcuts.html"
fi

open "$shortcuts_file"
