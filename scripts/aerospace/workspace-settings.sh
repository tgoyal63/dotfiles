#!/usr/bin/env sh

# Global Aerospace workspace preferences. Edit this file when your layout changes.

WORK_MONITOR="AORUS FI27Q"
SIDE_MONITOR="Built-in Retina Display"

WORK_MONITOR_WORKSPACES="1 2 3 7 8 9"
SIDE_MONITOR_WORKSPACES="4 5 6 0 o"

APP_ID_WORKSPACE_RULES='com.mitchellh.ghostty|1
com.microsoft.VSCode|1
app.zen-browser.zen|2
com.openai.chat|3
com.openai.codex|3
com.hnc.Discord|4
net.whatsapp.WhatsApp|4
ru.keepcoder.Telegram|4
com.apple.mail|4
com.spotify.client|5
com.obsproject.obs-studio|o
com.apple.Notes|7
com.apple.iCal|7
com.google.Chrome|8
com.brave.Browser|8'

APP_NAME_WORKSPACE_RULES='audacity|6
obsidian|7
notion|7
todoist|7
things|7
docker|9
orbstack|9
postman|9
insomnia|9'

SCREEN_SHARE_PRIVATE_APP_IDS='com.hnc.Discord
net.whatsapp.WhatsApp
com.spotify.client
com.obsproject.obs-studio'

is_screen_share_private_app() {
  private_app_id="$1"

  while IFS= read -r private_rule_app_id; do
    if [ "$private_app_id" = "$private_rule_app_id" ]; then
      unset private_app_id private_rule_app_id
      return 0
    fi
  done <<EOF
$SCREEN_SHARE_PRIVATE_APP_IDS
EOF

  unset private_app_id private_rule_app_id
  return 1
}

target_workspace_for_app() {
  route_app_id="$1"
  route_app_name_lower="$2"

  while IFS='|' read -r route_rule_app_id route_workspace; do
    if [ "$route_app_id" = "$route_rule_app_id" ]; then
      printf '%s\n' "$route_workspace"
      unset route_app_id route_app_name_lower route_rule_app_id route_app_name_substring route_workspace
      return
    fi
  done <<EOF
$APP_ID_WORKSPACE_RULES
EOF

  while IFS='|' read -r route_app_name_substring route_workspace; do
    case "$route_app_name_lower" in
      *"$route_app_name_substring"*)
        printf '%s\n' "$route_workspace"
        unset route_app_id route_app_name_lower route_rule_app_id route_app_name_substring route_workspace
        return
        ;;
    esac
  done <<EOF
$APP_NAME_WORKSPACE_RULES
EOF

  unset route_app_id route_app_name_lower route_rule_app_id route_app_name_substring route_workspace
  printf '%s\n' 0
}
