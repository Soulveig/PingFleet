# PingFleet

PingFleet is a small native macOS monitoring app inspired by PingInfoView.

## Features

- Track multiple hosts with periodic ICMP ping.
- Show online/offline state, last latency, average/min/max latency, packets sent/received, and loss percentage.
- Filter hosts by name or address.
- Add/remove hosts from the app.
- Import hosts from `.txt` or `.csv`.
- Export the current table to CSV.
- Russian/English interface text based on the system language.
- MacTreeSize-style automatic updates with a hosted JSON manifest and release notes.
- Keep host state in `~/Library/Application Support/PingFleet/hosts.json`.

## Dependencies

PingFleet does not use third-party source packages or bundled third-party libraries. The app is built with Swift Package Manager and links only against Apple system frameworks and the Swift runtime.

The app icon in `Assets/` is an AI-generated project asset created for PingFleet.

## License

PingFleet is released under the MIT License. See `LICENSE`.

## Run

```sh
swift run
```

## Build

```sh
swift build -c release
```

## Create a `.app` bundle

```sh
./Scripts/package-app.sh
open .build/release/PingFleet.app
```

The package script builds the release binary, adds update metadata, signs the app with the configured Developer ID certificate, and verifies the signature.

The default signing identity is:

```txt
Developer ID Application: Alexey Golovatyuk (B8GJVVNEFH)
```

Override release settings when needed:

```sh
VERSION=0.2.5 UPDATE_MANIFEST_URL=https://your-domain.example/pingfleet/update/ ./Scripts/package-app.sh
```

## Notarize

PingFleet uses the same stored notary profile as MacTreeSize by default:

```sh
./Scripts/notarize-app.sh
```

Full release packaging signs, notarizes, staples, creates the update zip, and updates `Updates/update.json`:

```sh
BASE_URL=https://your-domain.example/pingfleet ./Scripts/make-release.sh
```

## Auto Updates

PingFleet checks the URL from `MTUpdateManifestURL` in `Info.plist`. If it points to a folder, the app automatically appends `update.json`, matching the MacTreeSize update flow.

For a real public release:

1. Upload `PingFleet-0.2.5.zip` and `Updates/update.json` to your update host.
2. Replace the default `https://example.com/pingfleet/update/` URL with your production URL.
3. Keep `downloadURL` in `update.json` pointed at the notarized release zip.

Example manifest:

```json
{
  "version": "0.2.5",
  "downloadURL": "https://example.com/pingfleet/update/PingFleet-0.2.5.zip",
  "releaseNotes": "Renames the app to PingFleet and keeps MacTreeSize-style updates."
}
```

## Import Format

Plain text:

```txt
1.1.1.1
8.8.8.8
router.local
```

CSV:

```csv
Cloudflare DNS,1.1.1.1
Google DNS,8.8.8.8
Home Router,192.168.1.1
```
