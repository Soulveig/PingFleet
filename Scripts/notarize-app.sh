#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/.build/release/PingFleet.app"
SUBMIT_ZIP="$ROOT_DIR/.build/release/PingFleet-notary-submit.zip"
NOTARY_PROFILE="${NOTARY_PROFILE:-pingfleet-notary}"

if [ ! -d "$APP_DIR" ]; then
    echo "Missing $APP_DIR. Build the app first." >&2
    exit 1
fi

codesign --verify --deep --strict --verbose=2 "$APP_DIR"

rm -f "$SUBMIT_ZIP"
ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$SUBMIT_ZIP"

xcrun notarytool submit "$SUBMIT_ZIP" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait

xcrun stapler staple "$APP_DIR"
xcrun stapler validate "$APP_DIR"
spctl --assess --type execute --verbose=4 "$APP_DIR"

echo "Notarized and stapled $APP_DIR"
