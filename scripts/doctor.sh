#!/usr/bin/env bash
set -uo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
repo_dir="$(cd -- "$script_dir/.." && pwd -P)"
checks=0
failures=0
warnings=0
secret_shape_pattern='(sk-[A-Za-z0-9_-]{20,}|github_pat_[A-Za-z0-9_]{20,}|gh[pousr]_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9-]{20,}|[sr]k_live_[A-Za-z0-9]{20,})'

pass() {
  checks=$((checks + 1))
  printf 'PASS  %s\n' "$1"
}

fail() {
  checks=$((checks + 1))
  failures=$((failures + 1))
  printf 'FAIL  %s\n' "$1" >&2
}

warn() {
  checks=$((checks + 1))
  warnings=$((warnings + 1))
  printf 'WARN  %s\n' "$1"
}

check_command() {
  if command -v "$1" >/dev/null 2>&1; then
    pass "command: $1"
  else
    fail "command missing: $1"
  fi
}

check_app() {
  if [[ -d "$1" ]]; then
    pass "app: ${1##*/}"
  else
    fail "app missing: ${1##*/}"
  fi
}

check_link() {
  local source_path="$1"
  local target_path="$2"
  local current_target

  current_target="$(readlink "$target_path" 2>/dev/null || true)"
  if [[ "$current_target" == "$source_path" ]]; then
    pass "link: $target_path"
  else
    fail "link drift: $target_path (expected $source_path; found ${current_target:-a non-symlink or missing path})"
  fi
}

check_window_manager() {
  local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/aerospace"
  local active_config="$config_dir/aerospace.toml"
  local disabled_config="$config_dir/aerospace.yabai-disabled.toml"

  if [[ -L "$active_config" && "$(readlink "$active_config")" == "$disabled_config" ]]; then
    check_link "$disabled_config" "$active_config"
    if [[ -r "$disabled_config" ]] && python3.13 -c '
import sys, tomllib
with open(sys.argv[1], "rb") as config_file:
    config = tomllib.load(config_file)
if config.get("start-at-login") is not False:
    sys.exit("The yabai AeroSpace profile must set start-at-login = false")
' "$disabled_config"; then
      pass 'window manager profile: yabai (AeroSpace login disabled)'
    else
      fail 'invalid yabai-disabled AeroSpace profile'
    fi
    check_command yabai
    check_command skhd
    check_link "$repo_dir/yabairc" "$HOME/.config/yabai/yabairc"
    check_link "$repo_dir/skhdrc" "$HOME/.config/skhd/skhdrc"
    check_link "$repo_dir/scripts/yabai" "$HOME/.config/yabai/scripts"
    check_link "$repo_dir/scripts/aerospace/workspace-settings.sh" "$HOME/.config/yabai/workspace-settings.sh"
  else
    check_link "$repo_dir/aerospace.toml" "$active_config"
  fi
}

printf 'Dotfiles doctor\n\n'

for command_name in brew git zsh starship fzf zoxide atuin fnm bun python3.13 memo remindctl gh codexbar obsidian kiro-cli docker orbctl code; do
  check_command "$command_name"
done

for app_path in \
  /Applications/AeroSpace.app \
  /Applications/Finicky.app \
  /Applications/Ghostty.app \
  /Applications/Obsidian.app \
  /Applications/OrbStack.app \
  '/Applications/Visual Studio Code.app'; do
  check_app "$app_path"
done

check_link "$repo_dir/.zshrc" "$HOME/.zshrc"
check_window_manager
check_link "$repo_dir/atuin.toml" "$HOME/.config/atuin/config.toml"
check_link "$repo_dir/finicky.ts" "$HOME/.finicky.ts"
check_link "$repo_dir/ghostty.toml" "$HOME/.config/ghostty/config"
check_link "$repo_dir/starship.toml" "$HOME/.config/starship.toml"
check_link "$repo_dir/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"

if kiro_output="$("$repo_dir/scripts/setup-kiro-cli.sh" 2>&1)"; then
  pass 'Kiro CLI compatibility hooks'
else
  fail 'Kiro CLI compatibility hooks'
fi
printf '%s\n' "$kiro_output" | sed 's/^/      /'

if orb_status="$(orbctl status 2>&1)"; then
  if [[ "$orb_status" == "Running" ]]; then
    pass 'OrbStack backend'
  else
    warn "OrbStack backend: ${orb_status:-unknown status}"
  fi
else
  warn 'OrbStack status check failed'
  printf '%s\n' "$orb_status" | sed 's/^/      /'
fi

if docker_status="$(docker info --format '{{.ServerVersion}}' 2>&1)"; then
  pass 'Docker engine'
else
  warn 'Docker engine is unavailable'
  printf '%s\n' "$docker_status" | sed 's/^/      /'
fi

if [[ ! -d /Applications/Docker.app ]]; then
  pass 'Docker Desktop is absent'
else
  warn 'Docker Desktop is still installed'
fi

if ! command -v gemini >/dev/null 2>&1; then
  pass 'Gemini CLI is absent'
else
  warn 'Gemini CLI is still installed'
fi

reminders_status="$(remindctl status --plain --no-color --no-input 2>/dev/null || true)"
case "$reminders_status" in
  authorized|full-access) pass 'Apple Reminders access' ;;
  not-determined) warn 'Apple Reminders access is not configured (run: remind authorize)' ;;
  *) warn "Apple Reminders access: ${reminders_status:-unavailable}" ;;
esac

# The Atuin CLI adjusts database permissions even for a history listing.
# Query a private repo-local snapshot, so SQLite cannot touch live WAL sidecars.
if atuin_history_count="$(python3.13 - "$repo_dir" <<'PY'
import os
import shutil
import sqlite3
import sys
import tempfile
import tomllib
from pathlib import Path

try:
    atuin_home = os.environ.get("ATUIN_HOME", "")
    explicit_home = bool(atuin_home and Path(atuin_home).is_absolute())
    unified = Path(atuin_home) if explicit_home else Path.home() / ".atuin"
    legacy_config = Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config") / "atuin"
    legacy_data = Path(os.environ.get("XDG_DATA_HOME") or Path.home() / ".local/share") / "atuin"
    default_config = unified if explicit_home or (unified / "config.toml").is_file() else legacy_config
    config_dir = Path(os.environ.get("ATUIN_CONFIG_DIR") or default_config)
    data_dir = unified / "data" if explicit_home or (unified / "data").is_dir() else legacy_data
    config_path = config_dir / "config.toml"
    config = tomllib.loads(config_path.read_text()) if config_path.exists() else {}
    configured_path = os.environ.get("ATUIN_DB_PATH") or config.get("db_path")
    if not configured_path and (os.environ.get("ATUIN_DATA_DIR") or config.get("data_dir")):
        raise ValueError("custom Atuin data_dir requires manual inspection or an explicit db_path")
    if configured_path and (configured_path == ":memory:" or configured_path.startswith(("sqlite:", "file:"))):
        raise ValueError("custom Atuin database URI requires manual inspection")
    if configured_path and ("$$" in configured_path or "${" in configured_path and ":" in configured_path):
        raise ValueError("complex Atuin database path expansion requires manual inspection")
    db_path = Path(os.path.expandvars(configured_path)).expanduser() if configured_path else data_dir / "history.db"
    if not db_path.is_absolute():
        db_path = config_dir / db_path
    sources = [db_path, Path(str(db_path) + "-wal")]
    def signature(path):
        info = path.stat()
        return (info.st_dev, info.st_ino, info.st_size, info.st_mtime_ns, info.st_ctime_ns)
    before = [signature(path) if path.exists() else None for path in sources]
    if before[0] is None:
        raise FileNotFoundError("Atuin history database is missing")
    with tempfile.TemporaryDirectory(prefix=".doctor-atuin.", dir=sys.argv[1]) as directory:
        snapshot = Path(directory) / "history.db"
        for source, stamp, suffix in zip(sources, before, ("", "-wal")):
            if stamp is not None:
                target = Path(str(snapshot) + suffix)
                shutil.copyfile(source, target)
                target.chmod(0o600)
        after = [signature(path) if path.exists() else None for path in sources]
        if before != after:
            raise ValueError("history changed during snapshot; rerun doctor for a stable count")
        with sqlite3.connect(f"{snapshot.as_uri()}?mode=ro", uri=True) as database:
            database.execute("PRAGMA query_only = ON")
            print(database.execute("SELECT count(*) FROM history WHERE deleted_at IS NULL").fetchone()[0])
except (OSError, ValueError, TypeError, sqlite3.Error) as error:
    print(f"Read-only Atuin history check failed: {error}", file=sys.stderr)
    sys.exit(1)
PY
)"; then
  if [[ "$atuin_history_count" -gt 0 ]]; then
    pass "Atuin history snapshot: $atuin_history_count command(s)"
  else
    warn 'Atuin history is empty (run: atuin import zsh)'
  fi
else
  warn 'Atuin database is unavailable'
fi

if gh_status="$(gh auth status 2>&1)"; then
  pass 'GitHub CLI authentication'
else
  warn 'GitHub CLI authentication check failed (run: gh auth status)'
  printf '%s\n' "$gh_status" | sed 's/^/      /'
fi

if bundle_output="$(HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --verbose --no-upgrade --file "$repo_dir/Brewfile" 2>&1)"; then
  pass 'Homebrew bundle is installed'
else
  warn 'Homebrew bundle check failed; inspect the diagnostics below'
fi
printf '%s\n' "$bundle_output" | sed 's/^/      /'

if grep -ERIq --exclude-dir=.git --exclude-dir='.check-config.*' "$secret_shape_pattern" "$repo_dir" "$HOME/Library/Application Support/Code/User/settings.json"; then
  fail 'managed dotfiles contain a credential-shaped value'
else
  scan_status=$?
  if [[ "$scan_status" -eq 1 ]]; then
    pass 'managed dotfiles contain no credential-shaped values'
  else
    fail "credential-shaped value scan could not complete (exit $scan_status)"
  fi
fi

if config_output="$("$repo_dir/scripts/check-config.sh" 2>&1)"; then
  pass 'repository config validation'
else
  fail 'repository config validation'
fi
printf '%s\n' "$config_output" | sed 's/^/      /'

printf '\n%d doctor checks, %d failure(s), %d warning(s) (nested config totals reported above)\n' "$checks" "$failures" "$warnings"
[[ "$failures" -eq 0 ]]
