import AppKit
import Foundation
import SwiftUI

@MainActor
final class AppUpdater: ObservableObject {
    @Published private(set) var latestRelease: AppUpdateRelease?
    @Published private(set) var updateAvailable = false
    @Published private(set) var isChecking = false
    @Published private(set) var isInstalling = false
    @Published private(set) var title = L10n.updatesReadyTitle
    @Published private(set) var message = L10n.updatesReadyMessage
    @Published private(set) var statusIconName = "arrow.down.circle"
    @Published private(set) var statusColor = Color.accentColor

    private var hasCheckedThisSession = false

    func checkForUpdatesIfNeeded() {
        guard hasCheckedThisSession == false else { return }
        checkForUpdates()
    }

    func checkForUpdates() {
        guard isChecking == false, isInstalling == false else { return }
        hasCheckedThisSession = true

        guard let manifestURL = Self.manifestURL else {
            latestRelease = nil
            updateAvailable = false
            title = L10n.updatesNotConfiguredTitle
            message = L10n.updatesNotConfiguredMessage
            statusIconName = "exclamationmark.triangle"
            statusColor = .orange
            return
        }

        isChecking = true
        title = L10n.updatesCheckingTitle
        message = manifestURL.absoluteString
        statusIconName = "arrow.clockwise"
        statusColor = .secondary

        Task {
            do {
                var request = URLRequest(url: manifestURL)
                request.timeoutInterval = 15
                request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
                request.setValue("\(AppInfo.name)/\(AppInfo.version)", forHTTPHeaderField: "User-Agent")

                let (data, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                    throw AppUpdateError.badStatus(httpResponse.statusCode)
                }

                let release = try Self.decodeRelease(from: data)
                let isNewer = Self.compareVersions(release.version, AppInfo.version) == .orderedDescending

                latestRelease = release
                updateAvailable = isNewer
                isChecking = false

                if isNewer {
                    title = L10n.updateAvailableTitle(release.version)
                    message = L10n.updateAvailableMessage
                    statusIconName = "arrow.down.circle.fill"
                    statusColor = .green
                } else {
                    title = L10n.upToDateTitle
                    message = L10n.upToDateMessage(AppInfo.versionDisplay)
                    statusIconName = "checkmark.circle.fill"
                    statusColor = .green
                }
            } catch {
                latestRelease = nil
                updateAvailable = false
                isChecking = false
                title = L10n.updateErrorTitle
                message = error.localizedDescription
                statusIconName = "exclamationmark.triangle"
                statusColor = .orange
            }
        }
    }

    func installUpdate() {
        guard isInstalling == false, let release = latestRelease, updateAvailable else { return }

        isInstalling = true
        title = L10n.downloadingUpdateTitle(release.version)
        message = release.downloadURL.absoluteString
        statusIconName = "arrow.down.circle.fill"
        statusColor = .green

        Task {
            do {
                let downloadedArchive = try await Self.downloadArchive(from: release.downloadURL)
                title = L10n.preparingUpdateTitle
                message = L10n.unpackingUpdateMessage(release.version)

                let tempRoot = FileManager.default.temporaryDirectory
                    .appendingPathComponent("PingFleetUpdate-\(UUID().uuidString)", isDirectory: true)
                let archiveURL = tempRoot.appendingPathComponent("PingFleet.zip")
                let expandedURL = tempRoot.appendingPathComponent("expanded", isDirectory: true)

                try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
                try FileManager.default.moveItem(at: downloadedArchive, to: archiveURL)
                try FileManager.default.createDirectory(at: expandedURL, withIntermediateDirectories: true)
                try Self.runProcess("/usr/bin/ditto", arguments: ["-x", "-k", archiveURL.path, expandedURL.path])

                let newAppURL = try Self.findAppBundle(in: expandedURL)
                let currentAppURL = Bundle.main.bundleURL
                let installFolder = currentAppURL.deletingLastPathComponent()
                if let protectedFolderName = Self.protectedUserFolderName(for: currentAppURL) {
                    title = L10n.permissionMayBeRequiredTitle
                    message = L10n.permissionMayBeRequiredMessage(protectedFolderName)
                    try await Task.sleep(nanoseconds: 1_500_000_000)
                }

                guard FileManager.default.isWritableFile(atPath: installFolder.path) else {
                    throw AppUpdateError.installFolderNotWritable(installFolder.path)
                }

                title = L10n.installingUpdateTitle
                message = L10n.installingUpdateMessage
                try Self.launchInstallHelper(currentAppURL: currentAppURL, newAppURL: newAppURL, tempRoot: tempRoot)
                exit(0)
            } catch {
                isInstalling = false
                title = L10n.installUpdateErrorTitle
                message = error.localizedDescription
                statusIconName = "exclamationmark.triangle"
                statusColor = .orange
            }
        }
    }

    private static var manifestURL: URL? {
        let defaultValue = UserDefaults.standard.string(forKey: "UpdateManifestURL")
        let bundleValue = Bundle.main.object(forInfoDictionaryKey: "MTUpdateManifestURL") as? String
        let rawValues = [defaultValue, bundleValue, AppInfo.updateManifestURLString]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }

        for rawValue in rawValues where rawValue.isEmpty == false {
            guard let url = URL(string: rawValue), Self.isPlaceholderUpdateURL(url) == false else {
                continue
            }

            return Self.normalizedUpdateURL(url)
        }

        return nil
    }

    private static func normalizedUpdateURL(_ url: URL) -> URL {
        if url.host == "api.github.com" {
            return url
        }

        if url.host == "github.com" {
            let components = url.pathComponents.filter { $0 != "/" }
            if components.count >= 4, components[2] == "releases", components[3] == "latest" {
                return URL(string: "https://api.github.com/repos/\(components[0])/\(components[1])/releases/latest") ?? url
            }
        }

        if url.pathExtension.isEmpty {
            return url.appendingPathComponent("update.json")
        }

        return url
    }

    private static func isPlaceholderUpdateURL(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return host == "example.com" || host.hasSuffix(".example.com")
    }

    private static func decodeRelease(from data: Data) throws -> AppUpdateRelease {
        let decoder = JSONDecoder()
        if let manifest = try? decoder.decode(AppUpdateManifest.self, from: data) {
            return try manifest.release()
        }

        let githubRelease = try decoder.decode(GitHubReleaseManifest.self, from: data)
        return try githubRelease.release()
    }

    private static func compareVersions(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let left = lhs.split(separator: ".").map { Int($0) ?? 0 }
        let right = rhs.split(separator: ".").map { Int($0) ?? 0 }
        let count = max(left.count, right.count)

        for index in 0..<count {
            let a = index < left.count ? left[index] : 0
            let b = index < right.count ? right[index] : 0
            if a < b { return .orderedAscending }
            if a > b { return .orderedDescending }
        }

        return .orderedSame
    }

    private static func downloadArchive(from url: URL) async throws -> URL {
        let (downloadedURL, response) = try await URLSession.shared.download(from: url)
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            throw AppUpdateError.badStatus(httpResponse.statusCode)
        }
        return downloadedURL
    }

    private static func findAppBundle(in folder: URL) throws -> URL {
        guard let enumerator = FileManager.default.enumerator(
            at: folder,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            throw AppUpdateError.invalidArchive
        }

        for case let url as URL in enumerator {
            if url.pathExtension == "app", url.lastPathComponent == "\(AppInfo.name).app" {
                return url
            }
        }

        throw AppUpdateError.invalidArchive
    }

    private static func launchInstallHelper(currentAppURL: URL, newAppURL: URL, tempRoot: URL) throws {
        let helperURL = tempRoot.appendingPathComponent("install-update.sh")
        let script = """
        #!/bin/sh
        set -e
        APP_PID=\(getpid())
        CURRENT_APP=\(shellQuoted(currentAppURL.path))
        NEW_APP=\(shellQuoted(newAppURL.path))
        TEMP_ROOT=\(shellQuoted(tempRoot.path))
        LOG_FILE="$TEMP_ROOT/install.log"

        exec >> "$LOG_FILE" 2>&1
        echo "Starting PingFleet update at $(date)"
        echo "Current app: $CURRENT_APP"
        echo "New app: $NEW_APP"

        WAIT_COUNT=0
        while kill -0 "$APP_PID" 2>/dev/null && [ "$WAIT_COUNT" -lt 50 ]; do
            sleep 0.2
            WAIT_COUNT=$((WAIT_COUNT + 1))
        done

        if kill -0 "$APP_PID" 2>/dev/null; then
            kill -TERM "$APP_PID" 2>/dev/null || true
            sleep 1
        fi

        if kill -0 "$APP_PID" 2>/dev/null; then
            kill -KILL "$APP_PID" 2>/dev/null || true
            sleep 0.5
        fi

        BACKUP_APP="$CURRENT_APP.previous.$(date +%s)"
        if [ -e "$CURRENT_APP" ]; then
            /bin/mv "$CURRENT_APP" "$BACKUP_APP"
        fi

        /usr/bin/ditto "$NEW_APP" "$CURRENT_APP"
        /usr/bin/xattr -dr com.apple.quarantine "$CURRENT_APP" 2>/dev/null || true
        /usr/bin/open "$CURRENT_APP"
        if [ -n "${BACKUP_APP:-}" ] && [ -e "$BACKUP_APP" ]; then
            rm -rf "$BACKUP_APP"
        fi
        rm -rf "$TEMP_ROOT"
        """

        try script.write(to: helperURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: helperURL.path)

        let nullDevice = try FileHandle(forWritingTo: URL(fileURLWithPath: "/dev/null"))
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/nohup")
        process.arguments = ["/bin/sh", helperURL.path]
        process.standardOutput = nullDevice
        process.standardError = nullDevice
        try process.run()
    }

    private static func protectedUserFolderName(for url: URL) -> String? {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let protectedFolders = [
            ("Documents", home.appendingPathComponent("Documents").path),
            ("Desktop", home.appendingPathComponent("Desktop").path),
            ("Downloads", home.appendingPathComponent("Downloads").path)
        ]

        let appPath = url.standardizedFileURL.path
        return protectedFolders.first { _, folderPath in
            appPath == folderPath || appPath.hasPrefix(folderPath + "/")
        }?.0
    }

    private static func runProcess(_ executable: String, arguments: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw AppUpdateError.processFailed(executable, Int(process.terminationStatus))
        }
    }

    private static func shellQuoted(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }
}

struct AppUpdateManifest: Decodable {
    let version: String
    let downloadURL: URL
    let releaseNotes: String?

    func release() throws -> AppUpdateRelease {
        guard version.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            throw AppUpdateError.invalidManifest
        }

        return AppUpdateRelease(version: version, downloadURL: downloadURL, releaseNotes: releaseNotes)
    }
}

struct GitHubReleaseManifest: Decodable {
    let tagName: String
    let name: String?
    let body: String?
    let assets: [GitHubReleaseAsset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case body
        case assets
    }

    func release() throws -> AppUpdateRelease {
        let version = tagName.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingPrefix("v")
        guard version.isEmpty == false else {
            throw AppUpdateError.invalidManifest
        }

        let preferredAssetName = "\(AppInfo.name)-\(version).zip"
        let asset = assets.first { $0.name == preferredAssetName }
            ?? assets.first { $0.name.hasPrefix("\(AppInfo.name)-") && $0.name.hasSuffix(".zip") }
        guard let asset else {
            throw AppUpdateError.invalidManifest
        }

        return AppUpdateRelease(version: String(version), downloadURL: asset.browserDownloadURL, releaseNotes: body ?? name)
    }
}

struct GitHubReleaseAsset: Decodable {
    let name: String
    let browserDownloadURL: URL

    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadURL = "browser_download_url"
    }
}

struct AppUpdateRelease {
    let version: String
    let downloadURL: URL
    let releaseNotes: String?
}

enum AppUpdateError: LocalizedError {
    case badStatus(Int)
    case invalidManifest
    case invalidArchive
    case installFolderNotWritable(String)
    case processFailed(String, Int)

    var errorDescription: String? {
        switch self {
        case .badStatus(let code):
            return L10n.updateServerHTTPError(code)
        case .invalidManifest:
            return L10n.invalidUpdateManifest
        case .invalidArchive:
            return L10n.invalidUpdateArchive
        case .installFolderNotWritable(let path):
            return L10n.installFolderNotWritable(path)
        case .processFailed(let executable, let code):
            return L10n.processFailed(executable, code)
        }
    }
}
