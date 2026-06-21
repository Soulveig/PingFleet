import Foundation

enum AppInfo {
    static let name = "PingFleet"
    static let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.2.5"
    static let versionDisplay = "Version \(version)"
    static let updateManifestURLString = "https://example.com/pingfleet/update/"

    static let changelog = [
        ReleaseNote(
            version: "0.2.5",
            date: "2026-06-22",
            items: [
                "Changed the default ping interval to 1 second.",
                "Switched the project license to MIT.",
                "Prepared the project for publication as a new GitHub repository."
            ]
        ),
        ReleaseNote(
            version: "0.2.4",
            date: "2026-06-21",
            items: [
                "Moved the host filter into its own toolbar row above the action buttons.",
                "Kept the current action button sizing while giving the filter more horizontal space."
            ]
        ),
        ReleaseNote(
            version: "0.2.3",
            date: "2026-06-21",
            items: [
                "Removed the always-visible right details panel from the default window layout.",
                "Added a toolbar Details button that opens selected-host metrics and history only on demand."
            ]
        ),
        ReleaseNote(
            version: "0.2.2",
            date: "2026-06-21",
            items: [
                "Renamed the app to PingFleet after checking GitHub and web results for existing Ping-prefixed names.",
                "Kept automatic migration from earlier PingWatch and LatencyDeck host storage folders.",
                "Removed separate build-number handling so releases use only the public version.",
                "Added time stamps to the latency history graph."
            ]
        ),
        ReleaseNote(
            version: "0.2.1",
            date: "2026-06-21",
            items: [
                "Removed the build number from the visible version label.",
                "Added an in-app changelog to the Updates window.",
                "Added pasted-address list import alongside file import.",
                "Added time stamps to the latency history graph."
            ]
        ),
        ReleaseNote(
            version: "0.2.0",
            date: "2026-06-21",
            items: [
                "Added a native macOS interface for monitoring hosts with periodic ping.",
                "Added fixed toolbar labels, a menu-based ping interval selector, and a corrected app icon.",
                "Added Russian and English interface text.",
                "Added MacTreeSize-style JSON update manifests and in-app update installation.",
                "Added file import, CSV export, Developer ID signing, notarization, and stapling."
            ]
        ),
        ReleaseNote(
            version: "0.1.0",
            date: "2026-06-21",
            items: [
                "Created the first PingFleet prototype with host list, latency statistics, packet loss, and history details."
            ]
        )
    ]
}

struct ReleaseNote: Identifiable {
    var id: String { version }
    let version: String
    let date: String
    let items: [String]
}
