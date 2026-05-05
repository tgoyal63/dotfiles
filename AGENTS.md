# AGENTS.md

## Repo overview

macOS-only personal dotfiles. No build, test, lint, or CI. Config files are meant to be symlinked to their target locations (e.g. `~/.zshrc`, `~/.config/aerospace/aerospace.toml`).

## Structure

| File | Target / Purpose |
|---|---|
| `.zshrc` | Shell: Oh My Zsh + Starship + NVM + Bun |
| `aerospace.toml` | Aerospace tiling WM (10 workspaces, `alt`-based bindings) |
| `ghostty.toml` | Ghostty terminal (Dracula theme, 0.88 opacity) |
| `starship.toml` | Starship prompt config |
| `finicky.ts` | URL-to-browser router (Zen default, Chrome for Meet, Brave for YouTube) |
| `scripts/install-brew-apps.sh` | One-shot cask installer |
| `scripts/aerospace/spotify/` | AppleScript wrappers for media keys in Aerospace |

## Gotchas

- **Script path mismatch**: `aerospace.toml` binds media keys to `~/.config/aerospace/scripts/spotify/*.sh`, but scripts live here in `scripts/aerospace/spotify/`. Symlink the directory or update the paths if keys stop working.
- **Duplicate Bun config**: `.zshrc` has two identical `BUN_INSTALL` blocks (lines 114–116 and 118–120). Safe to remove one.
- **Hardcoded user path**: `.zshrc` line 109 hardcodes `/Users/sid/.opencode/bin`. Generalize if this repo is used on another machine.
- **Aerospace config path**: Aerospace expects its config at `~/.config/aerospace/aerospace.toml`, not in the dotfiles dir. Symlink or copy after changes.
