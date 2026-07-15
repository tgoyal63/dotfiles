# Dotfiles

macOS dotfiles tuned for a fast, strict-tiling, dev-first workflow.

## Workflow

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
| `scripts/link-configs.sh` | run manually | Safely create or refresh config symlinks |
| `scripts/check-config.sh` | run manually | Validate shell and application configs |
| `scripts/macos/fix-mission-control.sh` | run manually | Mission Control/AeroSpace defaults |
| `scripts/aerospace/workspace-settings.sh` | sourced by helper scripts | Global workspace, monitor, app routing, and privacy settings |
| `SHORTCUTS.md` | opened by `alt+shift+s` | Quick shortcut overview document |
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

From the repo root, preview the links and then apply them:

```bash
scripts/link-configs.sh --dry-run
scripts/link-configs.sh
```

The linker refreshes symlinks but refuses to overwrite regular files or directories. The `.zshrc` resolves the repo path automatically when symlinked. Put machine-specific shell settings in `zsh/local.zsh`; start from `zsh/local.zsh.example`.

## Validate Configs

Run the dependency-free repository checks after making changes:

```bash
scripts/check-config.sh
```

The checker validates shell syntax, executable permissions, Finicky syntax when Node is available, and installed AeroSpace, Ghostty, and Starship configs. AeroSpace is reloaded only when its active config points to this repo.

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
| `alt+1..0` / `alt+o` | Switch workspace |
| `alt+shift+1..0` / `alt+shift+o` | Move window to workspace |
| `alt+[` / `alt+]` | Previous/next workspace |
| `alt+backtick` | Toggle current/previous workspace |
| `alt+tab` | Focus next window, wrapping across monitors |
| `alt+/` | Toggle tile orientation |
| `alt+,` | Toggle accordion orientation |
| `alt+-` / `alt+=` | Resize |
| `alt+r` | Persistent resize mode |
| `alt+f` | Fullscreen |
| `alt+space` / `alt+shift+f` | Toggle floating/tiling |
| `alt+b` / `alt+shift+b` / `ctrl+alt+b` | Zen / Chrome / Brave |
| `alt+;` | One-shot app launcher mode |
| `alt+shift+tab` | Move current workspace to next monitor |
| `alt+m` | Focus next monitor |
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

Chrome handles Google work/auth/productivity links like Meet, Calendar, Gmail, Drive, Docs, Sheets, Slides, Forms, Accounts, Chat, Gemini, and Cloud Console.

Brave handles media links like YouTube, Twitch, Spotify web, SoundCloud, and Vimeo.

Modifier overrides apply to every link: hold Control for Zen, Option for Chrome, or Shift for Brave. Control wins over Option, which wins over Shift when multiple modifiers are held.

Before routing, Finicky removes common ad-tracking parameters such as `utm_*`, `gclid`, `fbclid`, `msclkid`, and Mailchimp campaign IDs while preserving functional URL parameters.

For direct browser access from anywhere, use `alt+b` for Zen, `alt+shift+b` for Chrome, or `ctrl+alt+b` for Brave. Press `alt+;` for the larger one-shot app launcher; the complete key map is in `SHORTCUTS.md`.
