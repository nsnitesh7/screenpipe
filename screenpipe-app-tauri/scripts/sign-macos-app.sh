#!/usr/bin/env bash
# Ad-hoc sign the screenpipe.app and all bundled binaries with a consistent
# identity so macOS TCC stops re-asking for screen/audio permissions.
# Run after build, or before/after copying to /Applications.

set -e
IDENTITY="screenpi.pe"
APP_PATH="${1:-}"

if [[ -z "$APP_PATH" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  APP_PATH="${SCRIPT_DIR}/../src-tauri/target/release/bundle/macos/screenpipe.app"
fi

if [[ ! -d "$APP_PATH" ]]; then
  echo "error: app not found at $APP_PATH"
  echo "usage: $0 [path/to/screenpipe.app]"
  exit 1
fi

MACOS_DIR="${APP_PATH}/Contents/MacOS"
echo "signing app at: $APP_PATH"

for binary in screenpipe screenpipe-app bun ui_monitor; do
  BIN_PATH="${MACOS_DIR}/${binary}"
  if [[ -f "$BIN_PATH" ]]; then
    echo "  signing $binary..."
    codesign --force --sign - --identifier "$IDENTITY" "$BIN_PATH"
  fi
done

# Sign any ffmpeg/ffprobe in Resources if present
RESOURCES="${APP_PATH}/Contents/Resources"
if [[ -d "$RESOURCES" ]]; then
  for name in ffmpeg ffprobe; do
    for f in "$RESOURCES"/${name}*; do
      if [[ -f "$f" ]]; then
        echo "  signing $(basename "$f")..."
        codesign --force --sign - --identifier "$IDENTITY" "$f"
      fi
    done
  done
fi

echo "  signing app bundle..."
codesign --force --sign - --identifier "$IDENTITY" "$APP_PATH"

echo "done. app and all binaries now use identity $IDENTITY"
