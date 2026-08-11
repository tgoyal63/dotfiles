#!/usr/bin/env bash
set -uo pipefail

workspace_root="${WORKSPACE_ROOT:-$HOME/projects}"
dirty_repositories=0

printf 'Workday · %s\n\n' "$(date '+%A, %d %B %Y · %H:%M')"

printf 'Environment\n'
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

printf '\nRepositories with local changes\n'
if [[ -d "$workspace_root" ]]; then
  while IFS= read -r git_directory; do
    repository="${git_directory%/.git}"
    repository_status="$(git -C "$repository" status --porcelain 2>/dev/null || true)"

    if [[ -n "$repository_status" ]]; then
      dirty_repositories=$((dirty_repositories + 1))
      branch="$(git -C "$repository" branch --show-current 2>/dev/null || true)"
      change_count="$(printf '%s\n' "$repository_status" | wc -l | tr -d '[:space:]')"
      display_path="${repository#"$HOME"/}"
      printf '  %s · %s · %s change(s)\n' "$display_path" "${branch:-detached}" "$change_count"
    fi
  done < <(find "$workspace_root" -mindepth 2 -maxdepth 4 -type d -name .git -prune -print 2>/dev/null | sort)
fi

if [[ "$dirty_repositories" -eq 0 ]]; then
  printf '  None\n'
fi

printf '\nQuick actions\n'
printf '  project      Fuzzy-switch repositories\n'
printf '  note add     Add an Apple Note\n'
printf '  remind add   Add an Apple Reminder\n'
printf '  doctor       Validate the complete environment\n'
