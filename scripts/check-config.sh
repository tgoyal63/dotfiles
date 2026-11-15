#!/usr/bin/env bash
set -uo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
repo_dir="$(cd -- "$script_dir/.." && pwd -P)"
checks=0
failures=0
skipped=0
validation_tmp="$(mktemp -d "$repo_dir/.check-config.XXXXXX")" || exit 1
trap 'rm -rf -- "$validation_tmp"' EXIT
# Keep validation caches and temporary files inside the repository.
export TMPDIR="$validation_tmp"
export XDG_CACHE_HOME="$validation_tmp/cache"
export STARSHIP_CACHE="$validation_tmp/starship"
export NODE_DISABLE_COMPILE_CACHE=1

pass() {
  checks=$((checks + 1))
  printf 'PASS  %s\n' "$1"
}

fail() {
  checks=$((checks + 1))
  failures=$((failures + 1))
  printf 'FAIL  %s\n' "$1" >&2

  if [[ -n "${2:-}" ]]; then
    printf '%s\n' "$2" | sed 's/^/      /' >&2
  fi
}

skip() {
  checks=$((checks + 1))
  skipped=$((skipped + 1))
  printf 'SKIP  %s\n' "$1"
}

run_check() {
  local label="$1"
  local output
  shift

  if output="$("$@" 2>&1)"; then
    pass "$label"
  else
    fail "$label" "$output"
  fi
}

validate_script_syntax() {
  local file
  local interpreter
  local status=0

  while IFS= read -r file; do
    case "$(head -n 1 "$file")" in
      *bash) interpreter=bash ;;
      *) interpreter=sh ;;
    esac

    "$interpreter" -n "$file" || status=1
  done < <(find "$repo_dir/scripts" -type f -name '*.sh' -print | sort)

  return "$status"
}

validate_zsh_syntax() {
  local file
  local status=0
  for file in "$repo_dir/.zshrc" "$repo_dir"/zsh/*.zsh; do
    zsh -n "$file" || status=1
  done
  return "$status"
}

validate_script_permissions() {
  local file
  local status=0

  while IFS= read -r file; do
    if [[ ! -x "$file" ]]; then
      printf 'Not executable: %s\n' "${file#"$repo_dir/"}" >&2
      status=1
    fi
  done < <(find "$repo_dir/scripts" -type f -name '*.sh' -print | sort)

  return "$status"
}

validate_zsh_integration_layout() {
  local starship_count
  local pre_line
  local grok_fpath_line
  local module_line
  local module_end_line
  local devrelay_line
  local grok_path_line
  local opencode_line
  local omz_line
  local autosuggestions_line
  local post_line
  local zle_line
  local highlighting_line
  local fzf_line
  local zoxide_line
  local atuin_line
  local last_code_line
  local path_export_count

  starship_count="$(grep -hF 'starship init zsh' "$repo_dir/.zshrc" "$repo_dir"/zsh/*.zsh | wc -l | tr -d '[:space:]')"
  if [[ "$starship_count" != 1 ]]; then
    printf 'Expected exactly one Starship initialization, found %s\n' "$starship_count" >&2
    return 1
  fi

  pre_line="$(grep -nF 'zshrc.pre.zsh' "$repo_dir/.zshrc" | head -n 1 | cut -d: -f1)"
  grok_fpath_line="$(grep -nFx 'fpath=(~/.grok/completions/zsh $fpath)' "$repo_dir/.zshrc" | head -n 1 | cut -d: -f1)"
  module_line="$(grep -nF 'for _zsh_module in' "$repo_dir/.zshrc" | head -n 1 | cut -d: -f1)"
  module_end_line="$(grep -nFx 'unset _zsh_module _zshrc_source' "$repo_dir/.zshrc" | head -n 1 | cut -d: -f1)"
  devrelay_line="$(grep -nFx 'export PATH="$HOME/.devrelay/bin:$PATH"' "$repo_dir/.zshrc" | head -n 1 | cut -d: -f1)"
  grok_path_line="$(grep -nFx 'export PATH="$HOME/.grok/bin:$PATH"' "$repo_dir/.zshrc" | head -n 1 | cut -d: -f1)"
  opencode_line="$(grep -nFx 'export PATH="$HOME/.opencode/bin:$PATH"' "$repo_dir/.zshrc" | head -n 1 | cut -d: -f1)"
  omz_line="$(grep -nE '^[[:space:]]*source "\$ZSH/oh-my-zsh\.sh"[[:space:]]*$' "$repo_dir/zsh/tools.zsh" | head -n 1 | cut -d: -f1)"
  autosuggestions_line="$(grep -nF 'source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh' "$repo_dir/.zshrc" | head -n 1 | cut -d: -f1)"
  post_line="$(grep -nF 'zshrc.post.zsh' "$repo_dir/.zshrc" | head -n 1 | cut -d: -f1)"
  highlighting_line="$(grep -nF 'source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' "$repo_dir/.zshrc" | head -n 1 | cut -d: -f1)"
  fzf_line="$(grep -nF 'source <(fzf --zsh)' "$repo_dir/zsh/tools.zsh" | head -n 1 | cut -d: -f1)"
  zoxide_line="$(grep -nF 'eval "$(zoxide init zsh)"' "$repo_dir/zsh/tools.zsh" | head -n 1 | cut -d: -f1)"
  atuin_line="$(grep -nF 'eval "$(atuin init zsh --disable-up-arrow --disable-ai)"' "$repo_dir/zsh/tools.zsh" | head -n 1 | cut -d: -f1)"
  last_code_line="$(awk 'NF && $0 !~ /^[[:space:]]*#/ { last = NR } END { print last }' "$repo_dir/.zshrc")"
  path_export_count="$(grep -Ec '^export PATH="\$HOME/\.(devrelay|grok|opencode)/bin:\$PATH"$' "$repo_dir/.zshrc")"

  if [[ -z "$pre_line" || -z "$grok_fpath_line" || -z "$module_line" || -z "$module_end_line" || -z "$devrelay_line" || -z "$grok_path_line" || -z "$opencode_line" || -z "$omz_line" || -z "$autosuggestions_line" || -z "$highlighting_line" || -z "$post_line" || -z "$fzf_line" || -z "$zoxide_line" || -z "$atuin_line" ]]; then
    printf 'One or more required Zsh integration lines are missing\n' >&2
    return 1
  fi

  if ! ((pre_line < grok_fpath_line && grok_fpath_line < module_line &&
    module_line < module_end_line && module_end_line < devrelay_line &&
    devrelay_line < grok_path_line && grok_path_line < opencode_line &&
    opencode_line < autosuggestions_line && autosuggestions_line < highlighting_line &&
    highlighting_line < post_line)); then
    printf 'Zsh integrations are not loaded in the required order\n' >&2
    return 1
  fi

  if [[ "$path_export_count" != 3 ]]; then
    printf 'Expected one PATH prepend each for DevRelay, Grok, and OpenCode\n' >&2
    return 1
  fi

  if grep -Eq '^[[:space:]]*[^#]*compinit' "$repo_dir/.zshrc"; then
    printf 'Oh My Zsh must own completion initialization; remove manual compinit from .zshrc\n' >&2
    return 1
  fi
  if ((post_line != last_code_line)); then
    printf 'Kiro post integration must be the last executable line\n' >&2
    return 1
  fi
  # Include local completion/ZLE additions in the ordering check.
  while IFS= read -r zle_line; do
    if ((zle_line > highlighting_line && zle_line != post_line)); then
      printf 'Completion/ZLE initialization must precede syntax highlighting (line %s)\n' "$zle_line" >&2
      return 1
    fi
  done < <(grep -nE '^[[:space:]]*[^#]*(source[[:space:]]|eval[[:space:]]|bindkey[[:space:]]|zle[[:space:]]+-[ANF]|(^|[[:space:];&])\.[[:space:]])' "$repo_dir/.zshrc" | cut -d: -f1)

  if ! ((omz_line < fzf_line && fzf_line < zoxide_line && zoxide_line < atuin_line)); then
    printf 'Oh My Zsh, FZF, zoxide, and Atuin are not loaded in the required order\n' >&2
    return 1
  fi

  grep -Fq 'if [[ -r /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]' "$repo_dir/.zshrc" &&
    grep -Fq 'if [[ -r /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]' "$repo_dir/.zshrc"
}

isolated_atuin_init() {
  local temp_dir="$1"
  # Do not inherit live Atuin path overrides or logging destinations.
  env -i PATH="$PATH" HOME="$temp_dir" TERM=xterm-256color TMPDIR="$temp_dir" \
    XDG_CONFIG_HOME="$temp_dir/config" XDG_DATA_HOME="$temp_dir/data" \
    XDG_CACHE_HOME="$temp_dir/cache" ATUIN_HOME="$temp_dir/atuin" \
    ATUIN_CONFIG_DIR="$temp_dir/config/atuin" \
    atuin init zsh --disable-up-arrow --disable-ai
}

validate_shell_navigation_tools() {
  local tool
  local temp_dir
  local result=0

  for tool in atuin fzf zoxide; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      printf 'Missing shell navigation tool: %s\n' "$tool" >&2
      return 1
    fi
  done

  temp_dir="$(mktemp -d)"

  fzf --zsh | zsh -n || result=1
  zoxide init zsh | zsh -n || result=1
  isolated_atuin_init "$temp_dir" | zsh -n || result=1

  rm -rf "$temp_dir"
  return "$result"
}

validate_zsh_plugin_runtime() {
  TERM=xterm-256color zsh -dfc '
    source "$1"
    source "$2"
    source "$3"

    (( ${+functions[prompt_starship_precmd]} )) || exit 1
    (( ${+functions[_zsh_autosuggest_start]} )) || exit 1
    (( ${+functions[_zsh_highlight_main__precmd_hook]} )) || exit 1
  ' zsh \
    "$repo_dir/zsh/prompt.zsh" \
    /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
    /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
}

validate_kiro_shell_integration() {
  "$repo_dir/scripts/setup-kiro-cli.sh"
}

extract_aerospace_routes() {
  awk '
    /^\[\[on-window-detected\]\]$/ {
      condition_type = ""
      pattern = ""
      workspace = ""
      next
    }
    /^if\.app-id = "/ {
      condition_type = "app-id"
      pattern = $0
      sub(/^if\.app-id = "/, "", pattern)
      sub(/"$/, "", pattern)
      next
    }
    /^if\.app-name-regex-substring = "/ {
      condition_type = "app-name-regex-substring"
      pattern = $0
      sub(/^if\.app-name-regex-substring = "/, "", pattern)
      sub(/"$/, "", pattern)
      next
    }
    /^run = "move-node-to-workspace / {
      workspace = $0
      sub(/^run = "move-node-to-workspace /, "", workspace)
      sub(/"$/, "", workspace)
      if (condition_type != "" && pattern != "") {
        print condition_type "|" pattern "|" workspace
      }
    }
  ' "$repo_dir/aerospace.toml"
}

validate_workspace_routes() {
  local expected_routes
  local actual_routes
  local app_id
  local app_name_substring
  local expected_workspace

  # shellcheck disable=SC1091
  . "$repo_dir/scripts/aerospace/workspace-settings.sh"

  expected_routes="$({
    printf '%s\n' "$APP_ID_WORKSPACE_RULES" | sed '/^$/d; s/^/app-id|/'
    printf '%s\n' "$APP_NAME_WORKSPACE_RULES" | sed '/^$/d; s/^/app-name-regex-substring|/'
  } | sort)"
  actual_routes="$(extract_aerospace_routes | sort)"

  if [[ "$expected_routes" != "$actual_routes" ]]; then
    diff -u <(printf '%s\n' "$expected_routes") <(printf '%s\n' "$actual_routes") || true
    return 1
  fi

  while IFS='|' read -r app_id expected_workspace; do
    if [[ "$(target_workspace_for_app "$app_id" '')" != "$expected_workspace" ]]; then
      printf 'Incorrect helper route for app id: %s\n' "$app_id" >&2
      return 1
    fi
  done <<<"$APP_ID_WORKSPACE_RULES"

  while IFS='|' read -r app_name_substring expected_workspace; do
    if [[ "$(target_workspace_for_app '' "test-$app_name_substring-window")" != "$expected_workspace" ]]; then
      printf 'Incorrect helper route for app name: %s\n' "$app_name_substring" >&2
      return 1
    fi
  done <<<"$APP_NAME_WORKSPACE_RULES"
}

validate_yabai_config() {
  sh -n "$repo_dir/yabairc" || return 1

  grep -Fq 'ad8d5adfdc39c76399599ae79a264f2525f6ca5e' "$repo_dir/scripts/yabai/install.sh" &&
    grep -Fq 'EXPECTED_MACOS_BUILD="26B131"' "$repo_dir/scripts/yabai/install.sh" &&
    grep -Fq '522c82e356484f3efca80f08b9720ba074a7ec8e6c06e4cf64426182032b7ece' "$repo_dir/scripts/yabai/install.sh" ||
    return 1

  grep -Fq 'link_path "$repo_dir/yabairc" "$HOME/.config/yabai/yabairc"' "$repo_dir/scripts/link-configs.sh" &&
    grep -Fq 'link_path "$repo_dir/skhdrc" "$HOME/.config/skhd/skhdrc"' "$repo_dir/scripts/link-configs.sh" &&
    grep -Fq 'link_path "$repo_dir/scripts/yabai" "$HOME/.config/yabai/scripts"' "$repo_dir/scripts/link-configs.sh" &&
    grep -Fq 'WORKSPACE_ORDER="1 2 3 4 5 6 7 8 9 0 c o"' "$repo_dir/scripts/aerospace/workspace-settings.sh" &&
    grep -Fq -- '--initialize-messaging' "$repo_dir/scripts/yabai/bootstrap-spaces.sh" &&
    grep -Fq 'group_by(.display)' "$repo_dir/scripts/yabai/bootstrap-spaces.sh" &&
    grep -Fq 'for workspace in c 6 4' "$repo_dir/scripts/yabai/bootstrap-spaces.sh" &&
    grep -Fq 'workspace_state_is_complete' "$repo_dir/scripts/yabai/startup.sh" &&
    grep -Fq 'Expected %s labeled workspaces after startup' "$repo_dir/scripts/yabai/startup.sh" &&
    grep -Fq '% ($displays | length)' "$repo_dir/scripts/yabai/move-space-next-display.sh" &&
    grep -Fq 'if ! move_error="$("$YABAI_BIN" -m space "$source_label" --display "$target_display"' "$repo_dir/scripts/yabai/move-space-next-display.sh" &&
    grep -Fq 'no other active Space was moved' "$repo_dir/scripts/yabai/move-space-next-display.sh" &&
    ! grep -Fq 'yabai-swap-' "$repo_dir/scripts/yabai/move-space-next-display.sh" &&
    grep -Fq '. "$script_dir/lib.sh"' "$repo_dir/scripts/yabai/arrange-workspaces.sh" &&
    grep -Fq '"$yabai_scripts/startup.sh"' "$repo_dir/yabairc" &&
    grep -Fq 'restoring AeroSpace' "$repo_dir/scripts/window-manager/use-yabai.sh" &&
    grep -Fq 'sudo -n "$YABAI_BIN" --load-sa' "$repo_dir/scripts/window-manager/use-yabai.sh" &&
    grep -Fq -- '--uninstall-service' "$repo_dir/scripts/window-manager/use-aerospace.sh" &&
    grep -Fq 'route-new-window' "$repo_dir/scripts/yabai/register-routes.sh" &&
    grep -Fq 'target_workspace_for_app' "$repo_dir/scripts/yabai/route-window.sh" &&
    grep -Fq -- '--toggle float' "$repo_dir/scripts/yabai/route-window.sh"
}

validate_skhd_config() {
  grep -Fq 'focus-space.sh 4' "$repo_dir/skhdrc" &&
    grep -Fq 'focus-space.sh 6' "$repo_dir/skhdrc" &&
    grep -Fq 'focus-space.sh c' "$repo_dir/skhdrc" &&
    grep -Fq 'focus-relative-space.sh prev' "$repo_dir/skhdrc" &&
    grep -Fq 'toggle-tiles.sh' "$repo_dir/skhdrc" &&
    grep -Fq 'restart.sh' "$repo_dir/skhdrc" &&
    grep -Fq 'move-space-next-display.sh' "$repo_dir/skhdrc" &&
    grep -Fq 'privacy-screen-share.sh' "$repo_dir/skhdrc"
}

validate_keyboard_parity() {
  local python_bin

  python_bin="$(command -v python3.13 2>/dev/null || command -v python3 2>/dev/null || true)"
  [[ -n "$python_bin" ]] || return 1
  "$python_bin" "$repo_dir/scripts/yabai/validate-keyboard-parity.py"
}

validate_documentation() {
  local expected_row='| `3` | AI | ChatGPT, Codex |'

  grep -Fqx "$expected_row" "$repo_dir/README.md" &&
    grep -Fqx "$expected_row" "$repo_dir/SHORTCUTS.md" &&
    grep -Fq '| `alt+b` | Open or focus Zen on workspace `2` |' "$repo_dir/SHORTCUTS.md" &&
    grep -Fq '| `alt+r` | Enter resize mode |' "$repo_dir/SHORTCUTS.md" &&
    grep -Fq '| Hold `Option` while opening any link | Force Chrome |' "$repo_dir/SHORTCUTS.md" &&
    grep -Fq '`alt+b` / `alt+shift+b` / `ctrl+alt+b`' "$repo_dir/README.md" &&
    grep -Fq 'scripts/link-configs.sh' "$repo_dir/README.md" &&
    grep -Fq 'scripts/setup-kiro-cli.sh' "$repo_dir/README.md" &&
    grep -Fq 'FZF, zoxide, Atuin, Python 3.13' "$repo_dir/README.md" &&
    grep -Fq 'Atuin owns `Ctrl-R`' "$repo_dir/README.md" &&
    grep -Fq 'vscode/settings.json' "$repo_dir/README.md" &&
    grep -Fq 'scripts/doctor.sh' "$repo_dir/README.md" &&
    grep -Fq '`project`' "$repo_dir/README.md" &&
    grep -Fq 'scripts/check-config.sh' "$repo_dir/README.md" &&
    grep -Fq 'official yabai SIP guide' "$repo_dir/README.md" &&
    grep -Fq 'The switch is transactional' "$repo_dir/README.md"
}

validate_ghostty_terminal_keys() {
  grep -Fqx 'macos-option-as-alt = true' "$repo_dir/ghostty.toml"
}

validate_atuin_config() {
  local temp_dir
  local result=0

  temp_dir="$(mktemp -d)"
  mkdir -p "$temp_dir/config/atuin" "$temp_dir/data"
  ln -s "$repo_dir/atuin.toml" "$temp_dir/config/atuin/config.toml"

  isolated_atuin_init "$temp_dir" >/dev/null || result=1

  rm -rf "$temp_dir"
  return "$result"
}

validate_vscode_settings() {
  local python_bin
  local secret_shape_pattern
  local stale_setting_pattern

  python_bin="$(command -v python3.13 2>/dev/null || command -v python3 2>/dev/null || true)"
  [[ -n "$python_bin" ]] || return 1

  "$python_bin" -m json.tool "$repo_dir/vscode/settings.json" >/dev/null || return 1

  grep -Fq '"terminal.integrated.macOptionIsMeta": true' "$repo_dir/vscode/settings.json" &&
    grep -Fq '"terminal.external.osxExec": "/Applications/Ghostty.app"' "$repo_dir/vscode/settings.json" &&
    grep -Fq '"terminal.integrated.defaultProfile.osx": "zsh"' "$repo_dir/vscode/settings.json" ||
    return 1

  stale_setting_pattern='"(C_Cpp\.default\.compilerPath|remote\.WSL\.debug|amazonQ\.[^"]*|aws\.[^"]*|augment\.[^"]*|codeium\.[^"]*|easycode[^"]*|tabnine\.[^"]*|vscord\.[^"]*)"[[:space:]]*:'
  if grep -Eq "$stale_setting_pattern" "$repo_dir/vscode/settings.json"; then
    printf 'VS Code settings still contain an obsolete setting\n' >&2
    return 1
  fi

  secret_shape_pattern='(sk-[A-Za-z0-9_-]{20,}|github_pat_[A-Za-z0-9_]{20,}|gh[pousr]_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9-]{20,}|[sr]k_live_[A-Za-z0-9]{20,})'
  if grep -Eiq "$secret_shape_pattern" "$repo_dir/vscode/settings.json"; then
    printf 'VS Code settings contain a credential-shaped value\n' >&2
    return 1
  fi

  grep -Fq 'link_path "$repo_dir/vscode/settings.json"' "$repo_dir/scripts/link-configs.sh"
}

validate_workflow_helpers() {
  grep -Fq 'for _zsh_module in path tools prompt aliases workflows local' "$repo_dir/.zshrc" &&
    grep -Fq 'project() {' "$repo_dir/zsh/workflows.zsh" &&
    grep -Fq '_note_search() {' "$repo_dir/zsh/workflows.zsh" &&
    grep -Fq 'remindctl show' "$repo_dir/zsh/workflows.zsh" &&
    grep -Fq 'doctor() {' "$repo_dir/zsh/workflows.zsh" &&
    grep -Fq 'workday() {' "$repo_dir/zsh/workflows.zsh" &&
    [[ -x "$repo_dir/scripts/doctor.sh" ]] &&
    [[ -x "$repo_dir/scripts/workday.sh" ]]
}

validate_aerospace_startup_apps() {
  local startup_block
  local expected_apps
  local actual_apps

  startup_block="$(sed -n '/^after-startup-command = \[/,/^\]/p' "$repo_dir/aerospace.toml")"
  expected_apps="$(printf '%s\n' Discord Ghostty Zen 'Visual Studio Code' | sort)"
  actual_apps="$(
    printf '%s\n' "$startup_block" |
      sed -nE "s/.*open -a ('([^']+)'|([^\"]+))\".*/\2\3/p" |
      sort
  )"

  if [[ "$actual_apps" != "$expected_apps" ]]; then
    diff -u <(printf '%s\n' "$expected_apps") <(printf '%s\n' "$actual_apps") || true
    return 1
  fi
}

validate_brewfile() {
  if grep -Eq '^[[:space:]]*(tap "(anomalyco|xdevplatform)/tap"|brew "(nvm|node@22|anomalyco/tap/opencode)"|cask "(claude-code|xdevplatform/tap/xurl)"|vscode "dodopayments.sentra-code")' "$repo_dir/Brewfile"; then
    printf 'Brewfile contains a retired installation baseline entry\n' >&2
    return 1
  fi

  [[ -f "$repo_dir/Brewfile" ]] &&
    grep -Fqx 'brew "fnm"' "$repo_dir/Brewfile" &&
    grep -Fqx 'brew "python@3.13"' "$repo_dir/Brewfile" &&
    grep -Fqx 'brew "opencode"' "$repo_dir/Brewfile" &&
    grep -Fqx 'brew "libpq", link: true' "$repo_dir/Brewfile" &&
    grep -Fqx 'brew "libpq@16"' "$repo_dir/Brewfile" &&
    grep -Fqx 'cask "claude-code@latest"' "$repo_dir/Brewfile" &&
    grep -Fq 'brew "asmvik/formulae/skhd"' "$repo_dir/Brewfile" &&
    grep -Fq 'brew "steipete/tap/remindctl"' "$repo_dir/Brewfile" &&
    grep -Fq 'cask "orbstack"' "$repo_dir/Brewfile" &&
    grep -Fq 'cask "kiro-cli"' "$repo_dir/Brewfile" &&
    grep -Fq 'vscode "openai.chatgpt"' "$repo_dir/Brewfile" &&
    grep -Fq 'brew bundle install --no-upgrade --file "$repo_dir/Brewfile"' "$repo_dir/scripts/install-brew-apps.sh" &&
    ruby -c "$repo_dir/Brewfile" >/dev/null || return 1

  # Groups follow the baseline, with the retained opt-in Things exception.
  ruby - "$repo_dir/Brewfile" "$repo_dir/scripts/install-brew-apps.sh" <<'RUBY'
baseline = File.read(ARGV[0])
installer = File.read(ARGV[1])
missing = []
optional = ["cask thingsmac"]
installer.scan(/^  install_(formulae|casks) (.+)$/).each do |kind, entries|
  directive = kind == "formulae" ? "brew" : "cask"
  declared = baseline.scan(/^#{directive} "([^"]+)"/).flatten
  entries.split.each do |entry|
    missing << "#{directive} #{entry}" unless declared.include?(entry) || optional.include?("#{directive} #{entry}")
  end
end
abort "Installer entries missing from Brewfile: #{missing.join(', ')}" unless missing.empty?
RUBY
}

validate_finicky_config() {
  node --experimental-strip-types --input-type=module -e '
    import { pathToFileURL } from "node:url";

    const modifierState = {
      shift: false,
      option: false,
      command: false,
      control: false,
      capsLock: false,
      fn: false
    };

    globalThis.finicky = {
      getModifierKeys: () => modifierState,
      matchHostnames: (matchers) => {
        const matcherList = Array.isArray(matchers) ? matchers : [matchers];
        return (url) => matcherList.some((matcher) =>
          matcher instanceof RegExp ? matcher.test(url.hostname) : matcher === url.hostname
        );
      }
    };

    const config = (await import(pathToFileURL(process.argv[1]).href)).default;

    if (config.defaultBrowser !== "Zen" || !Array.isArray(config.handlers)) {
      throw new Error("Finicky config has an invalid default browser or handlers list");
    }

    if (!Array.isArray(config.rewrite) || config.rewrite.length === 0) {
      throw new Error("Finicky config has an invalid rewrite list");
    }

    for (const rule of config.rewrite) {
      const originalUrl = "https://example.com/page?utm_source=test&utm_medium=email&dclid=a&fbclid=b&gclid=c&mc_cid=d&mc_eid=e&msclkid=f&keep=yes#section";
      const testUrl = new URL(originalUrl);

      if (typeof rule.match !== "function" || !rule.match(testUrl, { opener: null }) || typeof rule.url !== "function") {
        throw new Error("Finicky tracking rewrite did not match an HTTPS URL");
      }
      const rewrittenUrl = rule.url(testUrl, { opener: null });
      if (rewrittenUrl.href !== "https://example.com/page?keep=yes#section" || testUrl.href !== originalUrl) {
        throw new Error("Finicky tracking rewrite removed the wrong parameters");
      }
      if (!rule.match(new URL("http://example.com"), { opener: null }) || rule.match(new URL("mailto:person@example.com"), { opener: null })) {
        throw new Error("Finicky tracking rewrite matched the wrong URL protocols");
      }
    }

    for (const handler of config.handlers) {
      if (typeof handler.match === "function") {
        handler.match(new URL("https://example.com"), { opener: null });
      }
    }

    const resolveBrowser = (href, modifiers = {}) => {
      Object.assign(modifierState, {
        shift: false,
        option: false,
        command: false,
        control: false,
        capsLock: false,
        fn: false
      }, modifiers);

      const url = new URL(href);
      const handler = config.handlers.find((candidate) =>
        typeof candidate.match === "function" && candidate.match(url, { opener: null })
      );
      return handler?.browser ?? config.defaultBrowser;
    };

    const routingCases = [
      ["https://github.com", {}, "Zen"],
      ["https://meet.google.com/example", {}, "Google Chrome"],
      ["https://docs.google.com/document", {}, "Google Chrome"],
      ["https://music.youtube.com", {}, "Brave Browser"],
      ["https://youtu.be/example", {}, "Brave Browser"],
      ["https://www.twitch.tv/example", {}, "Brave Browser"],
      ["https://youtube.com.example.org", {}, "Zen"],
      ["https://github.com", { option: true }, "Google Chrome"],
      ["https://github.com", { shift: true }, "Brave Browser"],
      ["https://youtube.com", { control: true }, "Zen"],
      ["https://youtube.com", { control: true, option: true }, "Zen"]
    ];

    for (const [href, modifiers, expectedBrowser] of routingCases) {
      const actualBrowser = resolveBrowser(href, modifiers);
      if (actualBrowser !== expectedBrowser) {
        throw new Error(`Finicky routed ${href} to ${actualBrowser}, expected ${expectedBrowser}`);
      }
    }
  ' "$repo_dir/finicky.ts"
}

run_check 'zsh syntax (entrypoint and every module)' validate_zsh_syntax
run_check 'zsh integration ordering' validate_zsh_integration_layout
run_check 'shell workflow helpers' validate_workflow_helpers
run_check 'AeroSpace startup apps' validate_aerospace_startup_apps
run_check 'Homebrew bundle' validate_brewfile

if command -v atuin >/dev/null 2>&1 && command -v fzf >/dev/null 2>&1 && command -v zoxide >/dev/null 2>&1; then
  run_check 'shell navigation tool integration' validate_shell_navigation_tools
  run_check 'Atuin config' validate_atuin_config
else
  skip 'shell navigation tool integration (Atuin, FZF, or zoxide is unavailable)'
  skip 'Atuin config (Atuin is unavailable)'
fi

if [[ -r /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh && -r /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  run_check 'zsh plugin runtime hooks' validate_zsh_plugin_runtime
else
  skip 'zsh plugin runtime hooks (Homebrew plugins are unavailable)'
fi

if command -v kiro-cli >/dev/null 2>&1; then
  run_check 'Kiro CLI shell integration' validate_kiro_shell_integration
else
  skip 'Kiro CLI shell integration (Kiro CLI is unavailable)'
fi

run_check 'shell script syntax' validate_script_syntax
run_check 'shell script executable permissions' validate_script_permissions
run_check 'workspace routing stays synchronized' validate_workspace_routes
run_check 'yabai config and pinned installer' validate_yabai_config
run_check 'skhd shortcut parity' validate_skhd_config
run_check 'AeroSpace and skhd keyboard parity' validate_keyboard_parity
run_check 'key documentation stays synchronized' validate_documentation
run_check 'Ghostty Option key acts as Alt' validate_ghostty_terminal_keys
run_check 'VS Code settings' validate_vscode_settings
run_check 'clean whitespace' git -C "$repo_dir" diff --check

tracked_ignored_files=''
while IFS= read -r ignored_file; do
  if [[ -n "$ignored_file" && -e "$repo_dir/$ignored_file" ]]; then
    tracked_ignored_files+="${tracked_ignored_files:+$'\n'}$ignored_file"
  fi
done < <(git -C "$repo_dir" ls-files -ci --exclude-standard)

if [[ -n "$tracked_ignored_files" ]]; then
  fail 'ignored files are not present and tracked' "$tracked_ignored_files"
else
  pass 'ignored files are not present and tracked'
fi

if command -v node >/dev/null 2>&1 && node --experimental-strip-types -e '' >/dev/null 2>&1; then
  run_check 'Finicky TypeScript import, routing and rewrites' validate_finicky_config
else
  skip 'Finicky routing and rewrites (this Node version cannot load TypeScript)'
fi

ghostty_bin="$(command -v ghostty 2>/dev/null || true)"
if [[ -z "$ghostty_bin" && -x /Applications/Ghostty.app/Contents/MacOS/ghostty ]]; then
  ghostty_bin=/Applications/Ghostty.app/Contents/MacOS/ghostty
fi

if [[ -n "$ghostty_bin" ]]; then
  run_check 'Ghostty config' "$ghostty_bin" +validate-config --config-file="$repo_dir/ghostty.toml"
else
  skip 'Ghostty config (Ghostty is unavailable)'
fi

if command -v starship >/dev/null 2>&1; then
  run_check 'Starship config' env TERM=xterm-256color STARSHIP_CONFIG="$repo_dir/starship.toml" starship prompt
else
  skip 'Starship config (Starship is unavailable)'
fi

if command -v aerospace >/dev/null 2>&1; then
  active_aerospace_config="$(readlink "${XDG_CONFIG_HOME:-$HOME/.config}/aerospace/aerospace.toml" 2>/dev/null || true)"

  if [[ "$active_aerospace_config" == "$repo_dir/aerospace.toml" ]]; then
    run_check 'AeroSpace native config validation (dry run)' aerospace reload-config --dry-run --no-gui --warnings-as-errors
  else
    skip 'AeroSpace native config validation (yabai or another profile is selected; TOML and keyboard parity checked above)'
  fi
else
  skip 'AeroSpace native config validation (AeroSpace is unavailable; TOML and keyboard parity checked above)'
fi

printf '\n%d checks, %d failure(s), %d skipped.\n' "$checks" "$failures" "$skipped"

if [[ "$failures" -gt 0 ]]; then
  exit 1
fi
