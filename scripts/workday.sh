#!/usr/bin/env bash
set -uo pipefail

workspace_root="${WORKSPACE_ROOT:-$HOME/projects}"
include_network=1
dirty_repositories=0
ahead_repositories=0
behind_repositories=0
overdue_reminders=0
review_requests=0
priorities=()

usage() {
  cat <<'EOF'
Usage: workday [--quick]

Build a daily dashboard from Apple Calendar and Reminders, local Git
repositories, GitHub review requests, OrbStack/Docker, Atuin, and CodexBar.

Options:
  --quick   Skip GitHub and CodexBar network requests.
  -h        Show this help.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --quick) include_network=0 ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

run_with_timeout() {
  local seconds="$1"
  shift

  if command -v perl >/dev/null 2>&1; then
    perl -e '
      my $seconds = shift @ARGV;
      $SIG{ALRM} = sub { exit 124 };
      alarm $seconds;
      exec @ARGV or exit 127;
    ' "$seconds" "$@"
  else
    "$@"
  fi
}

add_priority() {
  [[ ${#priorities[@]} -ge 3 ]] || priorities+=("$1")
}

print_limited() {
  local output="$1"
  local limit="$2"
  local total

  total="$(printf '%s\n' "$output" | sed '/^[[:space:]]*$/d' | wc -l | tr -d '[:space:]')"
  printf '%s\n' "$output" | sed '/^[[:space:]]*$/d' | head -n "$limit" | sed 's/^/  /'
  if ((total > limit)); then
    printf '  … and %d more\n' "$((total - limit))"
  fi
}

calendar_script=$(cat <<'APPLESCRIPT'
set dayStart to current date
set time of dayStart to 0
set dayEnd to dayStart + (1 * days)
set eventRows to {}

tell application "Calendar"
  repeat with calendarItem in calendars
    set calendarName to name of calendarItem
    try
      set matchingEvents to every event of calendarItem whose start date is less than dayEnd and end date is greater than dayStart
      repeat with calendarEvent in matchingEvents
        set eventTitle to summary of calendarEvent
        if allday event of calendarEvent then
          set startLabel to "All day"
        else
          set startLabel to time string of (start date of calendarEvent)
        end if
        set end of eventRows to startLabel & " · " & eventTitle & " (" & calendarName & ")"
      end repeat
    end try
  end repeat
end tell

set text item delimiters of AppleScript to linefeed
return eventRows as text
APPLESCRIPT
)

printf 'Workday · %s\n' "$(date '+%A, %d %B %Y · %H:%M')"

printf '\nToday\n'
if calendar_output="$(run_with_timeout 6 osascript -e "$calendar_script" 2>/dev/null)"; then
  if [[ -n "$calendar_output" ]]; then
    print_limited "$(printf '%s\n' "$calendar_output" | sort)" 8
  else
    printf '  Calendar: no events today\n'
  fi
else
  printf '  Calendar: access unavailable or request timed out\n'
fi

if command -v remindctl >/dev/null 2>&1; then
  overdue_output="$(run_with_timeout 5 remindctl show overdue --plain --no-color --no-input 2>/dev/null || true)"
  today_output="$(run_with_timeout 5 remindctl show today --plain --no-color --no-input 2>/dev/null || true)"
  [[ "$overdue_output" == *"No reminders"* ]] && overdue_output=""
  [[ "$today_output" == *"No reminders"* ]] && today_output=""

  if [[ -n "$overdue_output" ]]; then
    overdue_reminders="$(printf '%s\n' "$overdue_output" | sed '/^[[:space:]]*$/d' | wc -l | tr -d '[:space:]')"
    printf '  Overdue reminders\n'
    print_limited "$overdue_output" 5
    add_priority "Clear $overdue_reminders overdue reminder(s)."
  fi

  if [[ -n "$today_output" ]]; then
    printf '  Due today\n'
    print_limited "$today_output" 5
  elif [[ -z "$overdue_output" ]]; then
    reminder_status="$(remindctl status --plain --no-color --no-input 2>/dev/null || true)"
    case "$reminder_status" in
      not-determined) printf '  Reminders: permission needed (run: remind authorize)\n' ;;
      denied|restricted) printf '  Reminders: access denied; enable it in System Settings\n' ;;
      *) printf '  Reminders: nothing due today\n' ;;
    esac
  fi
else
  printf '  Reminders: remindctl is not installed\n'
fi

printf '\nDevelopment environment\n'
if command -v orbctl >/dev/null 2>&1 && [[ "$(orbctl status 2>/dev/null || true)" == "Running" ]]; then
  printf '  OrbStack: running\n'
else
  printf '  OrbStack: stopped (run: orbctl start)\n'
fi

if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  printf '  Docker: ready\n'
else
  printf '  Docker: unavailable\n'
fi

if command -v atuin >/dev/null 2>&1; then
  if atuin_history="$(atuin history list --format '{command}' 2>/dev/null)"; then
    if [[ -n "$atuin_history" ]]; then
      atuin_history_count="$(printf '%s\n' "$atuin_history" | wc -l | tr -d '[:space:]')"
    else
      atuin_history_count=0
    fi

    if [[ "$atuin_history_count" -gt 0 ]]; then
      printf '  Atuin: %s command(s) indexed\n' "$atuin_history_count"
    else
      printf '  Atuin: history is empty (run: atuin import zsh)\n'
      add_priority 'Import existing Zsh history into Atuin.'
    fi
  else
    printf '  Atuin: database unavailable\n'
  fi
fi

printf '\nRepositories needing attention\n'
if [[ -d "$workspace_root" ]]; then
  while IFS= read -r git_directory; do
    repository="${git_directory%/.git}"
    repository_status="$(git -C "$repository" status --porcelain 2>/dev/null || true)"
    branch="$(git -C "$repository" branch --show-current 2>/dev/null || true)"
    upstream="$(git -C "$repository" rev-parse --abbrev-ref '@{upstream}' 2>/dev/null || true)"
    ahead=0
    behind=0
    details=()

    if [[ -n "$repository_status" ]]; then
      dirty_repositories=$((dirty_repositories + 1))
      change_count="$(printf '%s\n' "$repository_status" | wc -l | tr -d '[:space:]')"
      details+=("$change_count change(s)")
    fi

    if [[ -n "$upstream" ]]; then
      read -r behind ahead <<<"$(git -C "$repository" rev-list --left-right --count "$upstream...HEAD" 2>/dev/null || printf '0 0')"
      if ((ahead > 0)); then
        ahead_repositories=$((ahead_repositories + 1))
        details+=("$ahead ahead")
      fi
      if ((behind > 0)); then
        behind_repositories=$((behind_repositories + 1))
        details+=("$behind behind")
      fi
    fi

    if [[ ${#details[@]} -gt 0 ]]; then
      display_path="${repository#"$HOME"/}"
      detail_text="$(printf ' · %s' "${details[@]}")"
      detail_text="${detail_text# · }"
      printf '  %s · %s · %s\n' "$display_path" "${branch:-detached}" "$detail_text"
    fi
  done < <(find "$workspace_root" -mindepth 2 -maxdepth 4 -type d -name .git -prune -print 2>/dev/null | sort)
fi

if ((dirty_repositories == 0 && ahead_repositories == 0 && behind_repositories == 0)); then
  printf '  None\n'
else
  ((dirty_repositories > 0)) && add_priority "Review local changes in $dirty_repositories repository/repositories."
  ((ahead_repositories > 0)) && add_priority "Push commits from $ahead_repositories repository/repositories."
  ((behind_repositories > 0)) && add_priority "Update $behind_repositories behind repository/repositories."
fi

printf '\nGitHub\n'
if ! command -v gh >/dev/null 2>&1; then
  printf '  GitHub CLI: not installed\n'
elif ! run_with_timeout 2 gh auth token >/dev/null 2>&1; then
  printf '  GitHub CLI: authentication required (run: gh auth login)\n'
elif ((include_network == 0)); then
  printf '  Skipped in quick mode\n'
else
  review_output="$(
    run_with_timeout 5 gh search prs --review-requested=@me --state=open --limit=5 \
      --json number,title,repository \
      --template '{{range .}}{{.repository.nameWithOwner}}#{{.number}} · {{.title}}{{"\n"}}{{end}}' 2>/dev/null || true
  )"
  if [[ -n "$review_output" ]]; then
    review_requests="$(printf '%s\n' "$review_output" | sed '/^[[:space:]]*$/d' | wc -l | tr -d '[:space:]')"
    print_limited "$review_output" 5
    add_priority "Review $review_requests requested GitHub pull request(s)."
  else
    printf '  No review requests found, or GitHub is unreachable\n'
  fi
fi

printf '\nAI usage\n'
if ((include_network == 0)); then
  printf '  Skipped in quick mode\n'
elif command -v codexbar >/dev/null 2>&1; then
  codex_output="$(run_with_timeout 5 codexbar usage --provider codex --status --no-color 2>/dev/null || true)"
  if [[ -n "$codex_output" ]]; then
    print_limited "$codex_output" 5
  else
    printf '  CodexBar: usage unavailable\n'
  fi
else
  printf '  CodexBar: not installed\n'
fi

printf '\nSuggested focus\n'
if [[ ${#priorities[@]} -eq 0 ]]; then
  printf '  1. No urgent local signals; choose the day’s highest-value task.\n'
else
  for priority_index in "${!priorities[@]}"; do
    printf '  %d. %s\n' "$((priority_index + 1))" "${priorities[$priority_index]}"
  done
fi

printf '\nQuick actions\n'
printf '  project            Fuzzy-switch repositories\n'
printf '  remind today       Review today’s reminders\n'
printf '  remind add "Task"  Capture a reminder\n'
printf '  note add            Capture an Apple Note\n'
printf '  doctor              Validate the environment\n'
