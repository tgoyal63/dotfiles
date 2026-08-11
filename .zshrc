# Kiro CLI pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh"

# Modular zsh entrypoint for this dotfiles repo.

_zshrc_source="${${(%):-%N}:A}"
export DOTFILES_DIR="${DOTFILES_DIR:-${_zshrc_source:h}}"

if [[ ! -d "$DOTFILES_DIR/zsh" && -d "$HOME/dotfiles/zsh" ]]; then
  export DOTFILES_DIR="$HOME/dotfiles"
fi

for _zsh_module in path tools prompt aliases workflows local; do
  if [[ -r "$DOTFILES_DIR/zsh/${_zsh_module}.zsh" ]]; then
    source "$DOTFILES_DIR/zsh/${_zsh_module}.zsh"
  fi
done

unset _zsh_module _zshrc_source

if [[ -r /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

if command -v kiro-cli >/dev/null 2>&1 && (( ${+functions[compdef]} )); then
  source <(kiro-cli completion zsh)
fi

# Keep zsh-syntax-highlighting after every other in-shell ZLE integration.
if [[ -r /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# Kiro CLI post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh"
