# Dotfiles

macOS dotfiles tuned for a fast, strict-tiling, dev-first workflow. yabai is the
native-Spaces window manager; AeroSpace remains available as a rollback path.

## Workflow

| Workspace | Role | Apps |
|---|---|---|
| `1` | Dev / terminal | Ghostty, VS Code |
| `2` | Web | Zen Browser |
| `3` | AI | ChatGPT, Codex |
| `4` | Discord / comms | Discord, Telegram, Mail |
| `5` | Media | Spotify |
| `6` | WhatsApp / creation | WhatsApp, Audacity |
| `7` | Notes / tasks | Obsidian, Notion, Notes, Calendar, Todoist, Things |
| `8` | Work browser | Chrome, Brave |
| `9` | Dev utilities | OrbStack, Postman, Insomnia |
| `0` | Misc | Everything else |
| `c` | Discord Canary | Discord Canary |
| `o` | OBS | OBS Studio |

Native Spaces are identified by stable `ws-*` labels instead of display coordinates. Use `alt+shift+tab` to move the current Space to another display, or `alt+shift+m` to move the focused window. Physical display placement can be horizontal, vertical, or irregular.

## Included

| File | Target | Purpose |
|---|---|---|
| `.zshrc` | `~/.zshrc` | Small zsh module loader |
| `zsh/*.zsh` | sourced by `.zshrc` | PATH, tools, prompt, aliases, local overrides |
| `aerospace.toml` | `~/.config/aerospace/aerospace.toml` | Strict tiling, workspace routing, keybindings |
| `yabairc` | `~/.config/yabai/yabairc` | Native-Spaces tiling and routing bootstrap |
| `skhdrc` | `~/.config/skhd/skhdrc` | Global yabai keyboard shortcuts and modes |
| `ghostty.toml` | `~/.config/ghostty/config` | Ghostty theme and opacity |
| `starship.toml` | `~/.config/starship.toml` | Prompt layout |
| `finicky.ts` | `~/.finicky.ts` | Browser routing |
| `atuin.toml` | `~/.config/atuin/config.toml` | Local-first, secret-filtered shell history |
| `vscode/settings.json` | `~/Library/Application Support/Code/User/settings.json` | Sanitized VS Code user settings |
| `Brewfile` | used by Homebrew Bundle | Reproducible formula, cask, tap, and VS Code extension baseline |
| `scripts/install-brew-apps.sh` | run manually | Grouped Homebrew installer |
| `scripts/link-configs.sh` | run manually | Safely create or refresh config symlinks |
| `scripts/setup-kiro-cli.sh` | run manually | Install Kiro CLI's Zsh terminal integration |
| `scripts/check-config.sh` | run manually | Validate shell and application configs |
| `scripts/doctor.sh` | run with `doctor` | Validate the live macOS development environment |
| `scripts/workday.sh` | run with `workday` | Summarize tools and repositories needing attention |
| `scripts/macos/fix-mission-control.sh` | run manually | Mission Control/AeroSpace defaults |
| `scripts/macos/configure-yabai-spaces.sh` | run manually | Native per-display Spaces defaults for yabai |
| `scripts/aerospace/workspace-settings.sh` | sourced by helper scripts | Global workspace, monitor, app routing, and privacy settings |
| `scripts/yabai/` | `~/.config/yabai/scripts/` | Pinned installer, stable Space labels, routing, and window helpers |
| `SHORTCUTS.md` | opened by `alt+shift+s` | Quick shortcut overview document |
| `scripts/aerospace/spotify/` | `~/.config/aerospace/scripts/spotify/` | Spotify media key scripts |

## Install Apps

Install the complete Brewfile baseline:

```bash
scripts/install-brew-apps.sh
```

Install selected groups:

```bash
scripts/install-brew-apps.sh core browsers dev
scripts/install-brew-apps.sh notes media
```

Available groups are `core`, `browsers`, `dev`, `comms`, `notes`, `media`, and `all`.

With no group, the installer uses `brew bundle --no-upgrade` and `Brewfile` as the source of truth. It installs missing entries without broadly upgrading or removing software, and it never runs `brew bundle cleanup`. Selected groups retain the existing idempotent cask adoption behavior.
The `core` group includes FZF, zoxide, Atuin, Python 3.13, RemindCtl, skhd, zsh-autosuggestions, and zsh-syntax-highlighting. The `dev` group includes Kiro CLI. The `notes` group includes Memo and the Obsidian app; Obsidian's official CLI is bundled with the app rather than installed as a separate Homebrew formula.

Check the baseline without installing or removing anything:

```bash
brew bundle check --no-upgrade --file Brewfile
```

The Brewfile records the Homebrew-managed baseline, including the applications whose consolidation has been deferred. It intentionally excludes software without a valid Homebrew receipt.

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

Atuin owns `Ctrl-R`; its Up Arrow and AI bindings are disabled so standard shell navigation and Kiro remain unchanged. History stays local, common secret-bearing commands are filtered, and a selected result is placed at the prompt for review instead of running immediately. Import the existing history once with `atuin import zsh`. Register or log in only if encrypted cross-device history sync is wanted.

Memo provides Apple Notes access. `note search` uses a repo-managed FZF picker: the preview shows the note and Enter prints the selected note in the terminal. RemindCtl provides the Reminders workflow with due-date filters, search, priorities, URLs, and recurring reminders. Run `remind authorize` once if macOS has not granted access. The Obsidian CLI requires the Obsidian app to be running; check it with `obsidian --help` after launching the app.

Daily helpers:

| Command | Action |
|---|---|
| `project` | Fuzzy-switch to any Git repository under `$WORKSPACE_ROOT` or `~/projects` |
| `note [search [query]|add|list|view N|edit|delete|folders|open]` | Search or manage Apple Notes through Memo |
| `remind [today|overdue|week|search|add|edit|complete|delete|lists|app]` | Manage Apple Reminders through RemindCtl |
| `workday` | Daily calendar, reminders, environment, repository, GitHub, and AI-usage dashboard |
| `workday --quick` | Run the dashboard without GitHub or CodexBar network requests |
| `doctor` | Validate commands, apps, dotfile links, Docker, secrets, and repo configs |

`workday` derives up to three suggested priorities from overdue reminders, local changes, unpushed or behind repositories, and GitHub review requests. GitHub data appears after `gh auth login`; CodexBar failures are contained and never stop the report.

## yabai on macOS 27

The repository pins the audited macOS 27 compatibility fork to commit
`ad0a12d63f639534a296a1d065b0d04979f1b4db`. Its installer also pins the
verified macOS build and Dock hash, so an OS update cannot silently reuse stale
scripting-addition offsets.

Prepare the migration:

```bash
brew install asmvik/formulae/skhd
scripts/link-configs.sh
scripts/yabai/install.sh
scripts/macos/configure-yabai-spaces.sh
```

Full keyboard parity requires yabai's scripting addition. This weakens parts of
System Integrity Protection, so keep AeroSpace active until every step is
complete. Shut down, enter macOS Recovery, open Utilities -> Terminal, and run
the Apple Silicon macOS 13-or-newer command from the
[official yabai SIP guide](https://github.com/asmvik/yabai/wiki/Disabling-System-Integrity-Protection):

```bash
csrutil enable --without fs --without debug --without nvram
```

After returning to macOS, enable non-Apple-signed arm64e binaries and reboot:

```bash
sudo nvram boot-args=-arm64e_preview_abi
sudo reboot
```

Create a self-signed Code Signing certificate in Keychain Access with the name
`yabai-cert`, identity type `Self Signed Root`, and certificate type `Code
Signing`. Then install the scripting addition and perform the guarded switch:

```bash
scripts/yabai/enable-scripting-addition.sh
scripts/window-manager/use-yabai.sh
```

On macOS 26 and 27, an existing enabled `yabai` permission can remain bound to
an older code hash. If the guarded switch reports that yabai cannot access
accessibility features, open System Settings -> Privacy & Security -> Device
Control and Data Access, remove the existing `yabai` row, add
`/opt/homebrew/bin/yabai`, and enable it. Merely toggling the stale row off and
on does not update its stored code requirement.

The switch is transactional: yabai waits for all twelve logical workspaces and
their labels before skhd starts. If startup cannot repair the native Spaces or
pass the readiness gate, it stops yabai/skhd and restores AeroSpace. The
three-Space `--initialize-messaging` mode remains available for diagnostics, but
it is deliberately not accepted as keyboard-parity readiness.

The full mapping is stored by macOS Space UUID under
`~/.local/state/yabai/workspaces.tsv`. Moving a Space to another display does
not change its role. `alt+shift+a` reapplies the saved labels and routes every
open window through the shared bundle-ID table.

With the scripting addition active, `alt+shift+tab` physically moves the native
Space to the next display, wrapping from the last display back to the first, and
startup can create missing Spaces automatically.
If it is the source display's last user Space, yabai first creates an empty
placeholder because macOS requires every display to retain one Space.
If the scripting addition becomes unavailable during a running session, the
shortcut fails safely instead of swapping another display's active Space.

The scripting-addition step deliberately remains separate because it changes
system security policy, installs a root-loaded Dock payload, and adds one
hash-pinned `sudoers` command. Return to the preserved setup with
`scripts/window-manager/use-aerospace.sh`.

## Login Apps

The profile switchers ensure only one window manager owns login startup. yabai
starts only Discord, Ghostty, Zen, and Visual Studio Code; all other applications
remain available through `alt+;` and their direct workspace shortcuts.

## VS Code

The managed settings keep only core settings and configuration for installed extensions. They remove revoked credential fields, obsolete AI-extension settings, Windows/WSL paths, old terminal-session variables, and missing themes. The integrated terminal treats Option as Meta, uses Zsh, and opens external terminals in Ghostty.

Never store API keys or tokens in `vscode/settings.json`. Use environment variables or a system keychain instead.

## Validate Configs

Run the dependency-free repository checks after making changes:

```bash
scripts/check-config.sh
```

The checker validates shell syntax, integration ordering and runtime hooks, workflow helpers, Atuin and VS Code settings, Kiro CLI shell setup and completion, executable permissions, yabai/skhd migration invariants, Finicky syntax when Node is available, and installed AeroSpace, Ghostty, and Starship configs. AeroSpace is reloaded only when its active config points to this repo.

## Mission Control Profiles

AeroSpace and yabai need opposite settings for per-display Spaces. For yabai:

```bash
scripts/macos/configure-yabai-spaces.sh
```

For the AeroSpace rollback profile:

```bash
scripts/macos/fix-mission-control.sh
```

Both profiles keep Mission Control ordering stable, group windows by application,
and stop application activation from unexpectedly changing Spaces. The yabai
profile enables separate Spaces per display; the AeroSpace profile disables it.

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

Press `alt+shift+a` to restore saved Space labels and move open apps back to their role Spaces.

Edit `scripts/aerospace/workspace-settings.sh` to change the shared workspace order, app routing, or screen-share private apps used by both window managers.

No Space is pinned to a monitor. Arrange the Built-in, DELL, and AORUS displays
however you want, then move any native Space with `alt+shift+tab` once the
scripting addition is active.

## Screen Share Privacy

Focus the monitor you are sharing, then press `alt+shift+p`. yabai moves Discord, Discord Canary, WhatsApp, Spotify, and OBS windows from that display to the next display.

This is intentionally manual because macOS does not reliably expose which display is currently being shared to the window manager.

## Browser Routing

Finicky keeps Zen as the default browser.

Chrome handles Google work/auth/productivity links like Meet, Calendar, Gmail, Drive, Docs, Sheets, Slides, Forms, Accounts, Chat, Gemini, and Cloud Console.

Brave handles media links like YouTube, Twitch, Spotify web, SoundCloud, and Vimeo.

Modifier overrides apply to every link: hold Control for Zen, Option for Chrome, or Shift for Brave. Control wins over Option, which wins over Shift when multiple modifiers are held.

Before routing, Finicky removes common ad-tracking parameters such as `utm_*`, `gclid`, `fbclid`, `msclkid`, and Mailchimp campaign IDs while preserving functional URL parameters.

For direct browser access from anywhere, use `alt+b` for Zen, `alt+shift+b` for Chrome, or `ctrl+alt+b` for Brave. Press `alt+;` for the larger one-shot app launcher; the complete key map is in `SHORTCUTS.md`.
