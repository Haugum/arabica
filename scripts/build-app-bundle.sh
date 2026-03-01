#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="${1:-$ROOT_DIR/.build/Arabica.app}"
MACOS_DIR="$APP_DIR/Contents/MacOS"
BUILD_CONFIGURATION="${ARABICA_BUILD_CONFIGURATION:-release}"
CODE_SIGN_IDENTITY="${ARABICA_CODESIGN_IDENTITY:--}"

cd "$ROOT_DIR"
swift build -c "$BUILD_CONFIGURATION" --product Arabica
BIN_DIR="$(swift build -c "$BUILD_CONFIGURATION" --product Arabica --show-bin-path)"
BIN_PATH="$BIN_DIR/Arabica"

if [[ ! -x "$BIN_PATH" ]]; then
    echo "Missing built binary at $BIN_PATH" >&2
    exit 1
fi

if [[ "$APP_DIR" != *.app ]] || [[ "$APP_DIR" == "/" ]] || [[ "$APP_DIR" == "$ROOT_DIR" ]]; then
    echo "Refusing to overwrite unsafe app path: $APP_DIR" >&2
    exit 1
fi

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"

cp "$BIN_PATH" "$MACOS_DIR/Arabica"
cp "$ROOT_DIR/Support/Info.plist" "$APP_DIR/Contents/Info.plist"

codesign_args=(--force --options runtime)

if [[ "$CODE_SIGN_IDENTITY" == "-" ]]; then
    codesign_args+=(--sign - --timestamp=none)
else
    codesign_args+=(--sign "$CODE_SIGN_IDENTITY" --timestamp)
fi

codesign "${codesign_args[@]}" "$MACOS_DIR/Arabica"
codesign "${codesign_args[@]}" "$APP_DIR"

echo "$APP_DIR"
