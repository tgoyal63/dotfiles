# Dotfiles

macOS dotfiles tuned for a fast, strict-tiling, dev-first workflow.

## Workflow

| Workspace | Role | Apps |
|---|---|---|
| `1` | Dev / terminal | Ghostty, VS Code |
| `2` | Web | Zen Browser |
| `3` | AI | ChatGPT |
| `4` | Comms | Discord, WhatsApp, Telegram, Mail |
| `5` | Media | Spotify |
| `6` | Creation | Audacity |
| `7` | Notes / tasks | Obsidian, Notion, Notes, Calendar, Todoist, Things |
| `8` | Work browser | Chrome, Brave |
| `9` | Dev utilities | Docker, OrbStack, Postman, Insomnia |
| `0` | Misc | Everything else |
| `o` | OBS

Workspaces are not pinned to monitors. Use `alt+shift+tab` to move the current workspace to another monitor, or `alt+shift+m` to move the focused window to another monitor.

## Included

| File | Target | Purpose |
|---|---|---|
| `.zshrc` | `~/.zshrc` | Small zsh module loader |
| `zsh/*.zsh` | sourced by `.zshrc` | PATH, tools, prompt, aliases, local overrides |
| `aerospace.toml` | `~/.config/aerospace/aerospace.toml` | Strict tiling, workspace routing, keybindings |
| `ghostty.toml` | `~/.config/ghostty/config` | Ghostty theme and opacity |
| `starship.toml` | `~/.config/starship.toml` | Prompt layout |
| `finicky.ts` | `~/.finicky.ts` | Browser routing |
| `scripts/install-brew-apps.sh` | run manually | Grouped Homebrew installer |
| `scripts/macos/fix-mission-control.sh` | run manually | Mission Control/AeroSpace defaults |
| `scripts/aerospace/workspace-settings.sh` | sourced by helper scripts | Global workspace, monitor, app routing, and privacy settings |
| `shortcuts.html` | opened by `alt+shift+s` | Quick shortcut overview page |
| `scripts/aerospace/spotify/` | `~/.config/aerospace/scripts/spotify/` | Spotify media key scripts |

## Install Apps

Install everything:

```bash
scripts/install-brew-apps.sh
```

Install selected groups:

```bash
scripts/install-brew-apps.sh core browsers dev
scripts/install-brew-apps.sh notes media
```

Available groups are `core`, `browsers`, `dev`, `comms`, `notes`, `media`, and `all`.

The installer is idempotent for casks: Homebrew-managed apps are skipped, unavailable optional casks are skipped, existing unmanaged apps are adopted when possible, and existing app conflicts are skipped instead of stopping the whole install.

## Link Configs

From the repo root:

```bash
mkdir -p "$HOME/.config/aerospace" "$HOME/.config/ghostty"
ln -sfn "$PWD/.zshrc" "$HOME/.zshrc"
ln -sfn "$PWD/aerospace.toml" "$HOME/.config/aerospace/aerospace.toml"
ln -sfn "$PWD/scripts/aerospace" "$HOME/.config/aerospace/scripts"
ln -sfn "$PWD/ghostty.toml" "$HOME/.config/ghostty/config"
ln -sfn "$PWD/starship.toml" "$HOME/.config/starship.toml"
ln -sfn "$PWD/finicky.ts" "$HOME/.finicky.ts"
```

The `.zshrc` resolves the repo path automatically when symlinked. Put machine-specific shell settings in `zsh/local.zsh`; start from `zsh/local.zsh.example`.

## Mission Control Fix

AeroSpace works best when macOS Spaces stops fighting it. Apply the defaults fix:

```bash
scripts/macos/fix-mission-control.sh
```

This does four things:

- Keeps Mission Control from rearranging Spaces by recent use.
- Enables `Group windows by application`, which fixes tiny/broken Mission Control previews with AeroSpace.
- Disables separate Spaces per display for better AeroSpace stability.
- Stops macOS from switching Spaces automatically when activating apps.

Log out and back in after running the script so `Displays have separate Spaces` fully updates.

## Keybindings

| Binding | Action |
|---|---|
| `alt+h/j/k/l` | Focus left/down/up/right |
| `alt+shift+h/j/k/l` | Move window left/down/up/right |
| `alt+1..0` | Switch workspace |
| `alt+shift+1..0` | Move window to workspace |
| `alt+/` | Toggle tile orientation |
| `alt+,` | Toggle accordion orientation |
| `alt+-` / `alt+=` | Resize |
| `alt+f` | Fullscreen |
| `alt+shift+f` | Toggle floating/tiling |
| `alt+shift+tab` | Move current workspace to next monitor |
| `alt+shift+m` | Move focused window to next monitor |
| `alt+shift+p` | Move sensitive apps off the focused monitor for screen share |
| `alt+shift+a` | Restore app workspace routing and monitor arrangement |
| `alt+shift+s` | Open the shortcuts overview page |
| `alt+enter` | New Ghostty window |
| `alt+shift+;` | Service mode |

## Workspace Arrangement

Press `alt+shift+a` to manually restore open apps to their role workspaces, then restore the default workspace monitor layout.

Edit `scripts/aerospace/workspace-settings.sh` to change the global workspace layout, app routing, monitor targets, or screen-share private apps used by the helper scripts.

Work display `AORUS FI27Q`: `1`, `2`, `3`, `7`, `8`, `9`.

Side display `Built-in Retina Display`: `4`, `5`, `6`, `0`, `o`.

This does not force-pin workspaces, so you can still move any workspace afterward with `alt+shift+tab`.

## Screen Share Privacy

Focus the monitor you are sharing, then press `alt+shift+p`. AeroSpace moves Discord, WhatsApp, Spotify, and OBS windows from that focused monitor to the other monitor.

This is intentionally manual because macOS does not reliably expose which display is currently being shared to Aerospace.

## Browser Routing

Finicky keeps Zen as the default browser.

Chrome handles Google work/auth/productivity links like Meet, Calendar, Gmail, Drive, Docs, Sheets, Slides, and Accounts.

Brave handles media links like YouTube, Twitch, Spotify web, and SoundCloud.

Ambiguous links like GitHub, Notion, Linear, Figma, and Slack default to Zen. Hold Option while opening one to force Chrome, or Shift to force Brave.
