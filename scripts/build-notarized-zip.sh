#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="${APP_DIR:-$ROOT_DIR/.build/Arabica.app}"
DIST_DIR="${DIST_DIR:-$ROOT_DIR/dist}"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT_DIR/Support/Info.plist")"
ARTIFACT_NAME="Arabica-${VERSION}-macos.zip"
ARTIFACT_PATH="$DIST_DIR/$ARTIFACT_NAME"
NOTARY_PROFILE="${ARABICA_NOTARY_PROFILE:-}"
CODE_SIGN_IDENTITY="${ARABICA_CODESIGN_IDENTITY:-}"
TEMP_BASE_DIR="${TMPDIR:-/tmp}"
TEMP_DIR="$(mktemp -d "${TEMP_BASE_DIR%/}/arabica-notarize.XXXXXX")"
TEMP_ARTIFACT_PATH="$TEMP_DIR/$ARTIFACT_NAME"

cleanup() {
    rm -rf "$TEMP_DIR"
}

trap cleanup EXIT

if [[ -z "$CODE_SIGN_IDENTITY" ]] || [[ "$CODE_SIGN_IDENTITY" == "-" ]]; then
    echo "ARABICA_CODESIGN_IDENTITY must be set to a Developer ID Application identity." >&2
    exit 1
fi

if [[ -z "$NOTARY_PROFILE" ]]; then
    echo "ARABICA_NOTARY_PROFILE must be set to a notarytool keychain profile name." >&2
    exit 1
fi

"$ROOT_DIR/scripts/build-app-bundle.sh" "$APP_DIR" >/dev/null

codesign --verify --deep --strict "$APP_DIR" >/dev/null

mkdir -p "$DIST_DIR"
rm -f "$ARTIFACT_PATH"

(
    cd "$(dirname "$APP_DIR")"
    zip -qry -X "$TEMP_ARTIFACT_PATH" "$(basename "$APP_DIR")"
)

xcrun notarytool submit "$TEMP_ARTIFACT_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$APP_DIR"
xcrun stapler validate "$APP_DIR"
spctl --assess --type execute --verbose=4 "$APP_DIR" >/dev/null

(
    cd "$(dirname "$APP_DIR")"
    zip -qry -X "$ARTIFACT_PATH" "$(basename "$APP_DIR")"
)

echo "$ARTIFACT_PATH"
