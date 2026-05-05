# Path setup. Keep this fast and side-effect free.

typeset -U path PATH

_path_prepend() {
  [[ -d "$1" ]] || return
  path=("$1" ${path:#$1})
}

_path_prepend "/opt/homebrew/bin"
_path_prepend "/opt/homebrew/sbin"
_path_prepend "$HOME/bin"
_path_prepend "$HOME/.local/bin"
_path_prepend "$HOME/.opencode/bin"

export BUN_INSTALL="$HOME/.bun"
_path_prepend "$BUN_INSTALL/bin"

export PATH
unset -f _path_prepend
