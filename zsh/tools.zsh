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

if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --use-on-cd)"
fi

# FZF keeps file/directory pickers on Ctrl-T and Alt-C. Atuin is initialized
# afterwards so it is the single owner of Ctrl-R history search.
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

if command -v atuin >/dev/null 2>&1; then
  eval "$(atuin init zsh --disable-up-arrow --disable-ai)"
fi
