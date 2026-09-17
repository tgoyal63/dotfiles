#!/usr/bin/env bash
set -euo pipefail

YABAI_REPOSITORY="https://github.com/AhsanFazal/yabai.git"
YABAI_COMMIT="ad0a12d63f639534a296a1d065b0d04979f1b4db"
EXPECTED_MACOS_BUILD="26A428"
EXPECTED_DOCK_SHA256="b704affba65f732ffd6676c3bb22c94abc737ee73af8bdf29a5ef02650cde33e"
PREFIX="${PREFIX:-/opt/homebrew}"
YABAI_CERT="${YABAI_CERT:-}"

actual_build="$(sw_vers -buildVersion)"
actual_dock_sha256="$(shasum -a 256 /System/Library/CoreServices/Dock.app/Contents/MacOS/Dock | awk '{print $1}')"

if [[ "$actual_build" != "$EXPECTED_MACOS_BUILD" || "$actual_dock_sha256" != "$EXPECTED_DOCK_SHA256" ]]; then
  printf 'Refusing an unverified yabai build. Expected macOS %s / Dock %s.\n' "$EXPECTED_MACOS_BUILD" "$EXPECTED_DOCK_SHA256" >&2
  printf 'Found macOS %s / Dock %s. Re-run the offset verifier before updating this installer.\n' "$actual_build" "$actual_dock_sha256" >&2
  exit 1
fi

build_dir="$(mktemp -d "${TMPDIR:-/tmp}/yabai-build.XXXXXX")"
trap 'rm -rf "$build_dir"' EXIT

git clone --quiet "$YABAI_REPOSITORY" "$build_dir/yabai"
git -C "$build_dir/yabai" checkout --quiet --detach "$YABAI_COMMIT"

actual_commit="$(git -C "$build_dir/yabai" rev-parse HEAD)"
[[ "$actual_commit" == "$YABAI_COMMIT" ]] || { printf 'Unexpected yabai commit: %s\n' "$actual_commit" >&2; exit 1; }

make -C "$build_dir/yabai" install
install -m 0755 "$build_dir/yabai/bin/yabai" "$PREFIX/bin/yabai"

if [[ -n "$YABAI_CERT" ]]; then
  codesign --force --sign "$YABAI_CERT" "$PREFIX/bin/yabai"
else
  codesign --force --sign - "$PREFIX/bin/yabai"
fi

codesign --verify --verbose "$PREFIX/bin/yabai"
printf 'Installed %s from pinned commit %s.\n' "$("$PREFIX/bin/yabai" --version)" "$YABAI_COMMIT"
