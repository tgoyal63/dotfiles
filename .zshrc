# Kiro CLI pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh"

# Modular zsh entrypoint for this dotfiles repo.

_zshrc_source="${${(%):-%N}:A}"
export DOTFILES_DIR="${DOTFILES_DIR:-${_zshrc_source:h}}"

if [[ ! -d "$DOTFILES_DIR/zsh" && -d "$HOME/dotfiles/zsh" ]]; then
  export DOTFILES_DIR="$HOME/dotfiles"
fi

alias claude-code='claude'

# Register Grok completions before the modular Oh My Zsh initialization.
fpath=(~/.grok/completions/zsh $fpath)

for _zsh_module in path tools prompt aliases workflows local; do
  if [[ -r "$DOTFILES_DIR/zsh/${_zsh_module}.zsh" ]]; then
    source "$DOTFILES_DIR/zsh/${_zsh_module}.zsh"
  fi
done

unset _zsh_module _zshrc_source

# Added by DevRelay installer
export PATH="$HOME/.devrelay/bin:$PATH"

# >>> grok installer >>>
export PATH="$HOME/.grok/bin:$PATH"
# <<< grok installer <<<

# Move standalone OpenCode first; the modular PATH is unique, so no duplicate remains.
export PATH="$HOME/.opencode/bin:$PATH"

if [[ -r /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# Keep zsh-syntax-highlighting after every other in-shell ZLE integration.
if [[ -r /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# Kiro CLI post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh"
