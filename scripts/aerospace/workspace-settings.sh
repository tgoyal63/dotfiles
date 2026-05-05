#!/usr/bin/env sh

# Global Aerospace workspace preferences. Edit this file when your layout changes.

WORK_MONITOR="AORUS FI27Q"
SIDE_MONITOR="Built-in Retina Display"

WORK_MONITOR_WORKSPACES="1 2 3 7 8 9"
SIDE_MONITOR_WORKSPACES="4 5 6 0 o"

is_screen_share_private_app() {
  case "$1" in
    com.hnc.Discord|net.whatsapp.WhatsApp|com.spotify.client|com.obsproject.obs-studio)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

target_workspace_for_app() {
  app_id="$1"
  app_name_lower="$2"

  case "$app_id" in
    com.mitchellh.ghostty|com.microsoft.VSCode)
      printf '%s\n' 1
      ;;
    app.zen-browser.zen)
      printf '%s\n' 2
      ;;
    com.openai.chat|com.openai.codex)
      printf '%s\n' 3
      ;;
    com.hnc.Discord|net.whatsapp.WhatsApp|ru.keepcoder.Telegram|com.apple.mail)
      printf '%s\n' 4
      ;;
    com.spotify.client)
      printf '%s\n' 5
      ;;
    com.obsproject.obs-studio)
      printf '%s\n' o
      ;;
    com.apple.Notes|com.apple.iCal)
      printf '%s\n' 7
      ;;
    com.google.Chrome|com.brave.Browser)
      printf '%s\n' 8
      ;;
    *)
      case "$app_name_lower" in
        *audacity*) printf '%s\n' 6 ;;
        *obsidian*|*notion*|*todoist*|*things*) printf '%s\n' 7 ;;
        *docker*|*orbstack*|*postman*|*insomnia*) printf '%s\n' 9 ;;
        *) printf '%s\n' 0 ;;
      esac
      ;;
  esac
}
