# Dotfiles Shortcuts

Open this overview with `alt+shift+s`.

## Workspaces

| Workspace | Role | Apps |
|---|---|---|
| `1` | Dev / terminal | Ghostty, VS Code |
| `2` | Web | Zen Browser |
| `3` | AI | ChatGPT, Codex |
| `4` | Comms | Discord, WhatsApp, Telegram, Mail |
| `5` | Media | Spotify |
| `6` | Creation | Audacity |
| `7` | Notes / tasks | Obsidian, Notion, Notes, Calendar, Todoist, Things |
| `8` | Work browser | Chrome, Brave |
| `9` | Dev utilities | Docker, OrbStack, Postman, Insomnia |
| `0` | Misc | Everything else |
| `o` | OBS | OBS Studio |

## Quick Controls

| Keys | Action |
|---|---|
| `alt+b` | Open or focus Zen on workspace `2` |
| `alt+shift+b` | Open or focus Chrome on workspace `8` |
| `ctrl+alt+b` | Open or focus Brave on workspace `8` |
| `alt+enter` | Open a new Ghostty window |
| `alt+;` | Enter one-shot app launcher mode |
| `alt+r` | Enter resize mode |
| `alt+shift+;` | Enter service mode |
| `alt+shift+s` | Open this overview |

## Navigation

| Keys | Action |
|---|---|
| `alt+h/j/k/l` or arrows | Focus left/down/up/right |
| `alt+shift+h/j/k/l` or arrows | Move window left/down/up/right |
| `alt+tab` | Focus next window, wrapping across monitors |
| `ctrl+alt+backtick` | Return to the previously focused window |
| `alt+m` | Focus the next monitor |

## Workspace Controls

| Keys | Action |
|---|---|
| `alt+1..0` / `alt+o` | Switch directly to a workspace |
| `alt+shift+1..0` / `alt+shift+o` | Move the focused window to a workspace |
| `alt+backtick` | Toggle current and previous workspace |
| `alt+[` / `alt+]` | Switch to previous/next workspace |
| `alt+shift+[` / `alt+shift+]` | Move the window to previous/next workspace and follow it |

## Window Actions

| Keys | Action |
|---|---|
| `alt+/` | Toggle tile orientation |
| `alt+,` | Toggle accordion orientation |
| `alt+space` / `alt+shift+f` | Toggle floating/tiling |
| `alt+-` / `alt+=` | Resize by a small step |
| `alt+shift+e` | Balance window sizes |
| `alt+f` | Toggle fullscreen |
| `alt+shift+r` | Reload the AeroSpace config |

## Resize Mode

Press `alt+r`, make as many adjustments as needed, then press `enter` or `esc`.

| Keys in mode | Action |
|---|---|
| `h/l` or left/right | Shrink/grow width |
| `k/j` or up/down | Shrink/grow height |
| `-` / `=` | Smart resize by a small step |
| `b` | Balance window sizes |

## App Launcher Mode

Press `alt+;`, then one key. The app opens on its role workspace and the mode exits.

| Key | App | Workspace |
|---|---|---|
| `z` / `c` / `b` | Zen / Chrome / Brave | `2` / `8` / `8` |
| `g` / `v` | Ghostty / VS Code | `1` |
| `a` / `x` | ChatGPT / Codex | `3` |
| `d` / `w` / `m` | Discord / WhatsApp / Mail | `4` |
| `s` | Spotify | `5` |
| `n` | Notes | `7` |
| `o` | OBS | `o` |
| `f` | Finder | `0` |
| `esc` | Cancel | — |

## Service Mode

Press `alt+shift+;`, then one action. The mode exits automatically.

| Key in mode | Action |
|---|---|
| `r` | Flatten/reset the workspace layout |
| `f` | Toggle floating/tiling |
| `b` | Balance window sizes |
| `c` | Close the focused window |
| `backspace` | Close every window except the focused one |
| `alt+shift+h/j/k/l` | Join the window left/down/up/right |
| `enter` / `esc` | Cancel |

## Monitor and Privacy Controls

| Keys | Action |
|---|---|
| `alt+m` | Focus the next monitor |
| `alt+shift+m` | Move the focused window to the next monitor |
| `alt+shift+tab` | Move the current workspace to the next monitor |
| `alt+shift+a` | Restore app routing and workspace monitor layout |
| `alt+shift+p` | Move private apps off the focused monitor before screen sharing |

## Media Controls

| Keys | Action |
|---|---|
| `F7` / `F8` / `F9` | Previous / play-pause / next in Spotify |
| `F10` / `F11` / `F12` | Mute / volume down / volume up in Spotify |

## Browser Routing

Direct AeroSpace shortcuts open or focus browsers; Finicky routes links opened from other apps.

| Link or modifier | Browser |
|---|---|
| Default | Zen |
| Hold `Control` while opening any link | Force Zen |
| Hold `Option` while opening any link | Force Chrome |
| Hold `Shift` while opening any link | Force Brave |
| Google work, auth, Chat, Gemini, and Cloud Console | Chrome |
| YouTube, Twitch, Spotify web, SoundCloud, and Vimeo | Brave |

Modifier priority is Control, then Option, then Shift when more than one is held.

Finicky also removes common `utm_*`, Google, Meta, Microsoft, and Mailchimp tracking parameters before opening links.

## Global Settings

Edit `scripts/aerospace/workspace-settings.sh` to change workspace placement, app routing, monitor targets, and screen-share private apps. Edit `finicky.ts` to change browser routing.
