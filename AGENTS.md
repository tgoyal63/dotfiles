# AGENTS.md

## Repo overview

macOS-only personal dotfiles. No build or CI; `scripts/check-config.sh` provides local validation. Config files are symlinked to their target locations (e.g. `~/.zshrc`, `~/.config/aerospace/aerospace.toml`).

## Structure

| File | Target / Purpose |
|---|---|
| `.zshrc` | Modular shell entrypoint: Oh My Zsh + Starship + fnm + Bun |
| `aerospace.toml` | AeroSpace rollback profile (12 workspaces, `alt`-based bindings) |
| `ghostty.toml` | Ghostty terminal (Dracula theme, 0.88 opacity) |
| `starship.toml` | Starship prompt config |
| `finicky.ts` | URL-to-browser router (Zen default, Chrome for Meet, Brave for YouTube) |
| `scripts/install-brew-apps.sh` | Brewfile baseline and grouped installer |
| `scripts/link-configs.sh` | Safe, repeatable config linker |
| `scripts/check-config.sh` | Repository config validation |
| `scripts/aerospace/spotify/` | AppleScript wrappers for media keys in Aerospace |

## Gotchas

- **Link layout**: Run `scripts/link-configs.sh`; it supports both a linked Aerospace scripts directory and the existing directory of individual links.
- **Mirrored routes**: App routing is represented in both `aerospace.toml` and `scripts/aerospace/workspace-settings.sh`; `scripts/check-config.sh` fails if they drift.
- **Window-manager profile**: AeroSpace expects `~/.config/aerospace/aerospace.toml`; the linker points it at this repo on initial setup and preserves an existing `aerospace.yabai-disabled.toml` target. Use `scripts/window-manager/` to switch modes. Doctor checks the selected profile; config validation never reloads the live manager.
