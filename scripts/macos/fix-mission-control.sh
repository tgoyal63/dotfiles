#!/usr/bin/env bash
set -euo pipefail

# Stabilize macOS Spaces/Mission Control for AeroSpace's virtual workspaces.
defaults write com.apple.dock mru-spaces -bool false
defaults write com.apple.dock expose-group-apps -bool true
defaults write com.apple.spaces spans-displays -bool true
defaults write NSGlobalDomain AppleSpacesSwitchOnActivate -bool false

killall Dock 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true

printf '%s\n' 'Mission Control defaults applied. Log out and back in for Displays have separate Spaces to fully update.'
