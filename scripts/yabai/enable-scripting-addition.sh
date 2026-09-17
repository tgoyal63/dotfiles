#!/usr/bin/env bash
set -euo pipefail

YABAI_BIN="${YABAI_BIN:-/opt/homebrew/bin/yabai}"
YABAI_CERT="${YABAI_CERT:-yabai-cert}"
SUDOERS_FILE="/private/etc/sudoers.d/yabai"

if csrutil status | grep -Fq 'status: enabled'; then
  printf '%s\n' 'SIP is fully enabled. Apply the documented partial-SIP setting from macOS Recovery first.' >&2
  exit 1
fi

if ! security find-identity -p codesigning | grep -Fq "\"$YABAI_CERT\""; then
  printf "Missing Code Signing identity '%s'. Create it in Keychain Access before continuing.\n" "$YABAI_CERT" >&2
  exit 1
fi

"$YABAI_BIN" --stop-service >/dev/null 2>&1 || true
codesign --force --sign "$YABAI_CERT" "$YABAI_BIN"
binary_hash="$(shasum -a 256 "$YABAI_BIN" | awk '{print $1}')"
sudoers_tmp="$(mktemp "${TMPDIR:-/tmp}/yabai-sudoers.XXXXXX")"
trap 'rm -f "$sudoers_tmp"' EXIT
printf '%s ALL=(root) NOPASSWD: sha256:%s %s --load-sa\n' "$(whoami)" "$binary_hash" "$YABAI_BIN" >"$sudoers_tmp"

visudo -cf "$sudoers_tmp"
sudo install -o root -g wheel -m 0440 "$sudoers_tmp" "$SUDOERS_FILE"
sudo visudo -cf "$SUDOERS_FILE"
sudo "$YABAI_BIN" --load-sa

printf '%s\n' 'The yabai scripting addition is installed and loaded.'
printf '%s\n' 'AeroSpace remains active; run scripts/window-manager/use-yabai.sh when ready to switch.'
printf '%s\n' 'If yabai was previously granted access with another signature, remove and re-add /opt/homebrew/bin/yabai in Device Control and Data Access.'
