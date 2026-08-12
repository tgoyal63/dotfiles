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

_note_search() {
  local query="${*:-}"
  local notes
  local selected
  local note_index

  if ! command -v memo >/dev/null 2>&1 || ! command -v fzf >/dev/null 2>&1; then
    printf 'note search requires memo and fzf\n' >&2
    return 1
  fi

  notes="$(
    memo notes 2>/dev/null |
      sed -nE 's/^[[:space:]]*([0-9]+)\. (.*)$/\1\t\2/p'
  )"

  if [[ -z "$notes" ]]; then
    printf 'No Apple Notes were found.\n'
    return 0
  fi

  selected="$(
    printf '%s\n' "$notes" |
      fzf --height=70% --reverse --border \
        --delimiter=$'\t' --with-nth=2.. --prompt='Note > ' --query="$query" \
        --preview='memo notes --view {1} 2>/dev/null' \
        --preview-window='right:60%:wrap'
  )" || return

  note_index="${selected%%$'\t'*}"
  [[ -n "$note_index" ]] && memo notes --view "$note_index"
}

note() {
  local action="${1:-search}"
  [[ $# -gt 0 ]] && shift

  case "$action" in
    search) _note_search "$@" ;;
    add) memo notes --add "$@" ;;
    list) memo notes "$@" ;;
    view) memo notes --view "$@" ;;
    edit) memo notes --edit "$@" ;;
    delete) memo notes --delete "$@" ;;
    folders) memo notes --flist ;;
    open) open -a Notes ;;
    *)
      printf 'Usage: note [search [query]|add|list|view N|edit|delete|folders|open]\n' >&2
      return 1
      ;;
  esac
}

remind() {
  local action="${1:-list}"
  [[ $# -gt 0 ]] && shift

  if ! command -v remindctl >/dev/null 2>&1; then
    printf 'remind requires remindctl\n' >&2
    return 1
  fi

  case "$action" in
    list) remindctl show open "$@" ;;
    today|tomorrow|week|overdue|upcoming|open|completed|all)
      remindctl show "$action" "$@"
      ;;
    lists) remindctl list "$@" ;;
    search) remindctl search "$@" ;;
    add) remindctl add "$@" ;;
    edit) remindctl edit "$@" ;;
    complete) remindctl complete "$@" ;;
    delete) remindctl delete "$@" ;;
    app) remindctl open --app ;;
    status|authorize|doctor) remindctl "$action" "$@" ;;
    help|-h|--help)
      printf '%s\n' 'Usage: remind [list|today|tomorrow|week|overdue|upcoming|search|add|edit|complete|delete|lists|app|status|authorize|doctor]'
      ;;
    *)
      printf 'Unknown remind action: %s\n' "$action" >&2
      printf '%s\n' 'Run: remind help' >&2
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
