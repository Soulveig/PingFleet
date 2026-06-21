#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

VERSION="${VERSION:-0.2.5}"
BASE_URL="${BASE_URL:-https://example.com/pingfleet}"
ZIP_PATH="$ROOT_DIR/.build/release/PingFleet-$VERSION.zip"
UPDATE_JSON_PATH="$ROOT_DIR/Updates/update.json"
NOTARIZE="${NOTARIZE:-1}"
RELEASE_NOTES="${RELEASE_NOTES:-Changes the default ping interval to 1 second, switches the project to the MIT license, and prepares GitHub publication.}"

VERSION="$VERSION" UPDATE_MANIFEST_URL="$BASE_URL/update/" ./Scripts/package-app.sh

if [ "$NOTARIZE" = "1" ]; then
    ./Scripts/notarize-app.sh
fi

rm -f "$ZIP_PATH"
(
    cd "$ROOT_DIR/.build/release"
    ditto -c -k --keepParent PingFleet.app "PingFleet-$VERSION.zip"
)

mkdir -p "$(dirname "$UPDATE_JSON_PATH")"
cat > "$UPDATE_JSON_PATH" <<JSON
{
  "version": "$VERSION",
  "downloadURL": "$BASE_URL/update/PingFleet-$VERSION.zip",
  "releaseNotes": "$RELEASE_NOTES"
}
JSON

echo "Created $ZIP_PATH"
echo "Updated $UPDATE_JSON_PATH"
