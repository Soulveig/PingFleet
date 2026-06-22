#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

VERSION="${VERSION:-0.2.11}"
UPDATE_MANIFEST_URL="${UPDATE_MANIFEST_URL:-https://api.github.com/repos/Soulveig/PingFleet/releases/latest}"
ZIP_PATH="$ROOT_DIR/.build/release/PingFleet-$VERSION.zip"
NOTARIZE="${NOTARIZE:-1}"

VERSION="$VERSION" UPDATE_MANIFEST_URL="$UPDATE_MANIFEST_URL" ./Scripts/package-app.sh

if [ "$NOTARIZE" = "1" ]; then
    ./Scripts/notarize-app.sh
fi

rm -f "$ZIP_PATH"
(
    cd "$ROOT_DIR/.build/release"
    ditto -c -k --keepParent PingFleet.app "PingFleet-$VERSION.zip"
)

echo "Created $ZIP_PATH"
