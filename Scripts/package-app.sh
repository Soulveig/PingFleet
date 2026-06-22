#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

VERSION="${VERSION:-0.2.11}"
IDENTITY="${IDENTITY:-Developer ID Application: Alexey Golovatyuk (B8GJVVNEFH)}"
UPDATE_MANIFEST_URL="${UPDATE_MANIFEST_URL:-https://api.github.com/repos/Soulveig/PingFleet/releases/latest}"
export VERSION UPDATE_MANIFEST_URL

swift build -c release

APP_DIR="$ROOT_DIR/.build/release/PingFleet.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$ROOT_DIR/.build/release/PingFleet" "$MACOS_DIR/PingFleet"
if [ -f "$ROOT_DIR/Assets/PingFleet.icns" ]; then
    cp "$ROOT_DIR/Assets/PingFleet.icns" "$RESOURCES_DIR/PingFleet.icns"
fi

cat > "$CONTENTS_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>PingFleet</string>
    <key>CFBundleIdentifier</key>
    <string>com.alexeygolovatyuk.pingfleet</string>
    <key>CFBundleName</key>
    <string>PingFleet</string>
    <key>CFBundleDisplayName</key>
    <string>PingFleet</string>
    <key>CFBundleIconFile</key>
    <string>PingFleet</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>__VERSION__</string>
    <key>CFBundleVersion</key>
    <string>__VERSION__</string>
    <key>CFBundleGetInfoString</key>
    <string>PingFleet __VERSION__, Copyright © 2026 Alexey Golovatyuk</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026 Alexey Golovatyuk</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>PingFleetUpdateURL</key>
    <string>__UPDATE_MANIFEST_URL__</string>
    <key>NSDocumentsFolderUsageDescription</key>
    <string>PingFleet needs access to update itself when the app is run from your Documents folder.</string>
    <key>NSDesktopFolderUsageDescription</key>
    <string>PingFleet needs access to update itself when the app is run from your Desktop folder.</string>
    <key>NSDownloadsFolderUsageDescription</key>
    <string>PingFleet needs access to update itself when the app is run from your Downloads folder.</string>
</dict>
</plist>
PLIST

perl -0pi -e 's/__VERSION__/$ENV{VERSION}/g; s#__UPDATE_MANIFEST_URL__#$ENV{UPDATE_MANIFEST_URL}#g' "$CONTENTS_DIR/Info.plist"

codesign --force --deep --options runtime --timestamp --sign "$IDENTITY" "$APP_DIR"
codesign --verify --deep --strict --verbose=2 "$APP_DIR"

echo "Created and signed $APP_DIR"
