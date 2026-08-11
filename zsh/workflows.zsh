# Focused helpers for everyday project, note, reminder, and system workflows.

project() {
  local workspace_root="${WORKSPACE_ROOT:-$HOME/projects}"
  local selected

  if [[ ! -d "$workspace_root" ]]; then
    printf 'Workspace root is unavailable: %s\n' "$workspace_root" >&2
    return 1
  fi

  if ! command -v fzf >/dev/null 2>&1; then
    printf 'project requires fzf\n' >&2
    return 1
  fi

  selected="$(
    find "$workspace_root" -mindepth 2 -maxdepth 4 -type d -name .git -prune -print 2>/dev/null |
      sed 's#/.git$##' |
      sort |
      fzf --height=60% --reverse --prompt='Project > ' \
        --preview 'git -C {} status --short --branch 2>/dev/null'
  )" || return

  [[ -n "$selected" ]] && cd "$selected"
}

note() {
  case "${1:-search}" in
    search) memo notes --search ;;
    add) memo notes --add ;;
    list) memo notes ;;
    folders) memo notes --flist ;;
    *)
      printf 'Usage: note [search|add|list|folders]\n' >&2
      return 1
      ;;
  esac
}

remind() {
  case "${1:-list}" in
    list) memo rem ;;
    add) memo rem --add ;;
    complete) memo rem --complete ;;
    edit) memo rem --edit ;;
    delete) memo rem --delete ;;
    *)
      printf 'Usage: remind [list|add|complete|edit|delete]\n' >&2
      return 1
      ;;
  esac
}

doctor() {
  "${DOTFILES_DIR:-$HOME/dotfiles}/scripts/doctor.sh" "$@"
}

workday() {
  "${DOTFILES_DIR:-$HOME/dotfiles}/scripts/workday.sh" "$@"
}
