# PingFleet

PingFleet is a small native macOS monitoring app inspired by PingInfoView.

## Features

- Track multiple hosts with periodic ICMP ping.
- Show online/offline state, last latency, packets sent, loss percentage, and last check time.
- Filter hosts by name or address.
- Add/remove hosts from the app.
- Import hosts from `.txt` or `.csv`.
- Export the current table to CSV.
- Russian/English interface text based on the system language.
- Automatic updates from GitHub Releases.
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
VERSION=0.2.9 UPDATE_MANIFEST_URL=https://api.github.com/repos/Soulveig/PingFleet/releases/latest ./Scripts/package-app.sh
```

## Notarize

PingFleet uses the `pingfleet-notary` notary profile by default:

```sh
./Scripts/notarize-app.sh
```

Full release packaging signs, notarizes, staples, and creates the update zip:

```sh
./Scripts/make-release.sh
```

## Auto Updates

PingFleet checks the URL from `PingFleetUpdateURL` in `Info.plist`. By default it points to the latest GitHub Release API endpoint:

```txt
https://api.github.com/repos/Soulveig/PingFleet/releases/latest
```

The updater reads the release tag and the `PingFleet-x.y.z.zip` asset from GitHub.

For a real public release:

1. Create a GitHub release such as `v0.2.9`.
2. Attach the notarized `PingFleet-0.2.9.zip` asset.
3. Keep the asset name in the `PingFleet-x.y.z.zip` format.

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
