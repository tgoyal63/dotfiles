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
| `9` | Dev utilities | OrbStack, Postman, Insomnia |
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
| `atuin.toml` | `~/.config/atuin/config.toml` | Local-first, secret-filtered shell history |
| `vscode/settings.json` | `~/Library/Application Support/Code/User/settings.json` | Sanitized VS Code user settings |
| `scripts/install-brew-apps.sh` | run manually | Grouped Homebrew installer |
| `scripts/link-configs.sh` | run manually | Safely create or refresh config symlinks |
| `scripts/setup-kiro-cli.sh` | run manually | Install Kiro CLI's Zsh terminal integration |
| `scripts/check-config.sh` | run manually | Validate shell and application configs |
| `scripts/doctor.sh` | run with `doctor` | Validate the live macOS development environment |
| `scripts/workday.sh` | run with `workday` | Summarize tools and repositories needing attention |
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
The `core` group includes FZF, zoxide, Atuin, Python 3.13, zsh-autosuggestions, and zsh-syntax-highlighting. The `dev` group includes Kiro CLI. The `notes` group includes Memo and the Obsidian app; Obsidian's official CLI is bundled with the app rather than installed as a separate Homebrew formula.

## Link Configs

From the repo root, preview the links and then apply them:

```bash
scripts/link-configs.sh --dry-run
scripts/link-configs.sh
```

The linker refreshes symlinks but refuses to overwrite regular files or directories. This includes VS Code and Atuin, so back up an existing user config before the first link. The `.zshrc` resolves the repo path automatically when symlinked. Put machine-specific shell settings in `zsh/local.zsh`; start from `zsh/local.zsh.example`.

## Set Up Kiro CLI

After installing the `dev` group and linking the configs, install Kiro CLI's Zsh integration:

```bash
scripts/setup-kiro-cli.sh
```

The setup script safely exposes Kiro CLI and its terminal helper under `~/.local/bin`, then installs Kiro's generated pre/post shell integration. Standard `kiro-cli` tab completion is loaded by `.zshrc`.

Kiro inline AI suggestions remain opt-in. Keep them disabled while using zsh-autosuggestions unless you intentionally want Kiro to replace the local history-based suggestion provider.

## Shell Productivity

The shell integrations avoid overlapping keybindings:

| Command / binding | Action |
|---|---|
| `Ctrl-R` | Search command history with Atuin |
| `Ctrl-T` | Insert files or directories with FZF |
| `Alt-C` | Change directory with FZF |
| `z <name>` | Jump to a frequently used directory with zoxide |
| `zi` | Interactively select a zoxide directory |

Atuin owns `Ctrl-R`; its Up Arrow and AI bindings are disabled so standard shell navigation and Kiro remain unchanged. History stays local, common secret-bearing commands are filtered, and a selected result is placed at the prompt for review instead of running immediately. Register or log in only if encrypted cross-device history sync is wanted.

Memo provides terminal access to Apple Notes and Reminders. Start with `memo notes`, `memo notes --search`, and `memo rem`. The Obsidian CLI requires the Obsidian app to be running; check it with `obsidian --help` after launching the app.

Daily helpers:

| Command | Action |
|---|---|
| `project` | Fuzzy-switch to any Git repository under `$WORKSPACE_ROOT` or `~/projects` |
| `note [search|add|list|folders]` | Search or manage Apple Notes through Memo |
| `remind [list|add|complete|edit|delete]` | Manage Apple Reminders through Memo |
| `workday` | Show OrbStack/Docker status and repositories with local changes |
| `doctor` | Validate commands, apps, dotfile links, Docker, secrets, and repo configs |

## VS Code

The managed settings keep only core settings and configuration for installed extensions. They remove revoked credential fields, obsolete AI-extension settings, Windows/WSL paths, old terminal-session variables, and missing themes. The integrated terminal treats Option as Meta, uses Zsh, and opens external terminals in Ghostty.

Never store API keys or tokens in `vscode/settings.json`. Use environment variables or a system keychain instead.

## Validate Configs

Run the dependency-free repository checks after making changes:

```bash
scripts/check-config.sh
```

The checker validates shell syntax, integration ordering and runtime hooks, workflow helpers, Atuin and VS Code settings, Kiro CLI shell setup and completion, executable permissions, Finicky syntax when Node is available, and installed AeroSpace, Ghostty, and Starship configs. AeroSpace is reloaded only when its active config points to this repo.

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
