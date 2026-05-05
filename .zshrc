# Modular zsh entrypoint for this dotfiles repo.

_zshrc_source="${${(%):-%N}:A}"
export DOTFILES_DIR="${DOTFILES_DIR:-${_zshrc_source:h}}"

if [[ ! -d "$DOTFILES_DIR/zsh" && -d "$HOME/dotfiles/zsh" ]]; then
  export DOTFILES_DIR="$HOME/dotfiles"
fi

for _zsh_module in path tools prompt aliases local; do
  if [[ -r "$DOTFILES_DIR/zsh/${_zsh_module}.zsh" ]]; then
    source "$DOTFILES_DIR/zsh/${_zsh_module}.zsh"
  fi
done

unset _zsh_module _zshrc_source
