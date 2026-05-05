# Tool setup. Load only what needs to exist for interactive work.

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
plugins=(git)

if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
fi

if [[ -r "$BUN_INSTALL/_bun" ]]; then
  source "$BUN_INSTALL/_bun"
fi

export NVM_DIR="$HOME/.nvm"

_lazy_load_nvm() {
  local command_name="$1"
  shift

  unset -f nvm node npm npx pnpm yarn corepack _lazy_load_nvm

  [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
  [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"

  "$command_name" "$@"
}

nvm() { _lazy_load_nvm nvm "$@"; }
node() { _lazy_load_nvm node "$@"; }
npm() { _lazy_load_nvm npm "$@"; }
npx() { _lazy_load_nvm npx "$@"; }
pnpm() { _lazy_load_nvm pnpm "$@"; }
yarn() { _lazy_load_nvm yarn "$@"; }
corepack() { _lazy_load_nvm corepack "$@"; }
