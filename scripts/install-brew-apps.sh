#!/bin/bash
set -euo pipefail

if ! command -v bun &> /dev/null && [ ! -x "$HOME/.bun/bin/bun" ]; then
  curl -fsSL https://bun.sh/install | bash
fi

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

brew tap nikitabobko/tap

brew install --quiet \
  starship

brew install --cask --quiet \
  aerospace \
  audacity \
  brave-browser \
  chatgpt \
  discord \
  finicky \
  firefox \
  localsend \
  ghostty \
  google-chrome \
  obs \
  spotify \
  whatsapp

if [ ! -d "/Applications/Zen.app" ] && [ ! -d "/Applications/Zen Browser.app" ]; then
  brew install --cask --quiet zen-browser
fi
