#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

VERSION="${VERSION:-0.2.7}"
BASE_URL="${BASE_URL:-https://example.com/pingfleet}"
ZIP_PATH="$ROOT_DIR/.build/release/PingFleet-$VERSION.zip"
UPDATE_JSON_PATH="$ROOT_DIR/Updates/update.json"
NOTARIZE="${NOTARIZE:-1}"
RELEASE_NOTES="${RELEASE_NOTES:-Adds multi-row host selection for targeted Start and Ping Now actions, keeps all-host pinging when nothing is selected, and aligns the status indicator column.}"

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
