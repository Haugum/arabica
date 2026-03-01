#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="${APP_DIR:-$ROOT_DIR/.build/Arabica.app}"
DIST_DIR="${DIST_DIR:-$ROOT_DIR/dist}"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT_DIR/Support/Info.plist")"
ARTIFACT_NAME="Arabica-${VERSION}-macos.zip"
ARTIFACT_PATH="$DIST_DIR/$ARTIFACT_NAME"

"$ROOT_DIR/scripts/build-app-bundle.sh" "$APP_DIR" >/dev/null

mkdir -p "$DIST_DIR"
rm -f "$ARTIFACT_PATH"

codesign --verify --deep --strict "$APP_DIR" >/dev/null
(
    cd "$(dirname "$APP_DIR")"
    zip -qry -X "$ARTIFACT_PATH" "$(basename "$APP_DIR")"
)

echo "$ARTIFACT_PATH"
