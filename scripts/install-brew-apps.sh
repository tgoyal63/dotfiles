#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/install-brew-apps.sh [group ...]

Groups:
  all       Install every group. This is the default.
  core      AeroSpace, Ghostty, Finicky, Starship, Bun, Oh My Zsh
  browsers  Zen, Chrome, Brave, Firefox
  dev       VS Code, Docker Desktop, OrbStack, Postman, Insomnia
  comms     ChatGPT, Discord, Telegram, WhatsApp
  notes     Obsidian, Notion, Todoist, Things
  media     Spotify, OBS, Audacity, LocalSend

Examples:
  scripts/install-brew-apps.sh
  scripts/install-brew-apps.sh core browsers dev
  scripts/install-brew-apps.sh notes media
EOF
}

install_shell_tools() {
  if ! command -v bun >/dev/null 2>&1 && [[ ! -x "$HOME/.bun/bin/bun" ]]; then
    curl -fsSL https://bun.sh/install | bash
  fi

  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi
}

install_formulae() {
  [[ $# -eq 0 ]] && return
  brew install --quiet "$@"
}

install_casks() {
  [[ $# -eq 0 ]] && return

  local cask
  for cask in "$@"; do
    install_cask "$cask"
  done
}

install_cask() {
  local cask="$1"
  local output
  local status

  if brew list --cask "$cask" >/dev/null 2>&1; then
    printf 'Cask already managed by Homebrew: %s\n' "$cask"
    return 0
  fi

  if ! brew info --cask "$cask" >/dev/null 2>&1; then
    printf 'Cask unavailable in Homebrew; skipping: %s\n' "$cask" >&2
    return 0
  fi

  if output="$(brew install --cask --quiet --adopt "$cask" 2>&1)"; then
    [[ -n "$output" ]] && printf '%s\n' "$output"
    return 0
  else
    status=$?
  fi

  if [[ "$output" == *"It seems there is already"* || "$output" == *"already exists"* ]]; then
    printf 'Cask artifact already exists outside Homebrew; skipping: %s\n' "$cask" >&2
    printf '%s\n' "$output" >&2
    return 0
  fi

  printf '%s\n' "$output" >&2
  return "$status"
}

install_core() {
  install_shell_tools
  brew tap nikitabobko/tap
  install_formulae starship
  install_casks aerospace finicky ghostty
}

install_browsers() {
  install_casks brave-browser firefox google-chrome zen-browser
}

install_dev() {
  install_casks visual-studio-code docker orbstack postman insomnia
}

install_comms() {
  install_casks chatgpt discord telegram whatsapp
}

install_notes() {
  install_casks obsidian notion todoist-app thingsmac
}

install_media() {
  install_casks audacity localsend obs spotify
}

install_group() {
  case "$1" in
    core) install_core ;;
    browsers) install_browsers ;;
    dev) install_dev ;;
    comms) install_comms ;;
    notes) install_notes ;;
    media) install_media ;;
    all)
      install_core
      install_browsers
      install_dev
      install_comms
      install_notes
      install_media
      ;;
    -h|--help|help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown group: %s\n\n' "$1" >&2
      usage >&2
      exit 1
      ;;
  esac
}

if [[ $# -eq 0 ]]; then
  set -- all
fi

for group in "$@"; do
  install_group "$group"
done
