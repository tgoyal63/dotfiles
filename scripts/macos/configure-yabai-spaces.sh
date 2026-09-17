#!/usr/bin/env bash
set -euo pipefail

# Native per-display Spaces are required for predictable yabai multi-monitor routing.
defaults write com.apple.dock mru-spaces -bool false
defaults write com.apple.dock expose-group-apps -bool true
defaults write com.apple.spaces spans-displays -bool false
defaults write NSGlobalDomain AppleSpacesSwitchOnActivate -bool false

killall Dock 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true

printf '%s\n' 'yabai Mission Control defaults applied. Log out and back in to activate Displays have separate Spaces.'
