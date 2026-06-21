import Foundation
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class PingMonitor: ObservableObject {
    @Published var hosts: [PingHost] = []
    @Published var intervalSeconds: Double = 1
    @Published var timeoutSeconds: Double = 1
    @Published var isRunning = false
    @Published var selectedHostID: PingHost.ID?
    @Published var showAddHost = false
    @Published var showImportHosts = false
    @Published var searchText = ""

    private let runner = PingRunner()
    private var monitorTask: Task<Void, Never>?
    private let storageURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = appSupport.appendingPathComponent("PingFleet", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        storageURL = directory.appendingPathComponent("hosts.json")
        Self.migrateLegacyStorageIfNeeded(to: storageURL, appSupport: appSupport)
        load()

        if hosts.isEmpty {
            hosts = [
                PingHost(name: "Cloudflare DNS", address: "1.1.1.1"),
                PingHost(name: "Google DNS", address: "8.8.8.8")
            ]
        }
    }

    var filteredHosts: [PingHost] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return hosts }
        return hosts.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.address.localizedCaseInsensitiveContains(searchText)
        }
    }

    var selectedHost: PingHost? {
        guard let selectedHostID else { return nil }
        return hosts.first(where: { $0.id == selectedHostID })
    }

    func addHost(name: String, address: String) {
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAddress.isEmpty else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        hosts.append(PingHost(name: trimmedName, address: trimmedAddress))
        save()
    }

    func removeSelectedHost() {
        guard let selectedHostID else { return }
        hosts.removeAll { $0.id == selectedHostID }
        self.selectedHostID = nil
        save()
    }

    func resetStats() {
        for index in hosts.indices {
            hosts[index].resetStats()
        }
        save()
    }

    func toggleRunning() {
        isRunning ? stop() : start()
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        monitorTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.pollEnabledHosts()
                let interval = UInt64((self?.intervalSeconds ?? 1) * 1_000_000_000)
                try? await Task.sleep(nanoseconds: interval)
            }
        }
    }

    func stop() {
        isRunning = false
        monitorTask?.cancel()
        monitorTask = nil
    }

    func pollOnce() {
        Task {
            await pollEnabledHosts()
        }
    }

    func importHosts(from url: URL) {
        guard let contents = try? String(contentsOf: url, encoding: .utf8) else { return }
        importHosts(fromText: contents)
    }

    func importHosts(fromText contents: String) {
        let newHosts = contents
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") }
            .map { line -> PingHost in
                let parts = line
                    .split(separator: ",", maxSplits: 1)
                    .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                if parts.count == 2 {
                    return PingHost(name: parts[0], address: parts[1])
                }
                return PingHost(name: line, address: line)
            }

        hosts.append(contentsOf: newHosts)
        save()
    }

    func exportCSV() -> String {
        var rows = ["Name,Address,Status,Last ms,Average ms,Min ms,Max ms,Sent,Received,Loss %,Last checked,Last error"]
        for host in hosts {
            rows.append([
                csv(host.name),
                csv(host.address),
                csv(L10n.state(host.state)),
                csv(format(host.lastLatencyMilliseconds)),
                csv(format(host.averageLatencyMilliseconds)),
                csv(format(host.minimumLatencyMilliseconds)),
                csv(format(host.maximumLatencyMilliseconds)),
                csv(String(host.sentCount)),
                csv(String(host.receivedCount)),
                csv(String(format: "%.1f", host.lossPercent)),
                csv(host.lastCheckedAt.map(Self.dateFormatter.string) ?? ""),
                csv(host.lastError ?? "")
            ].joined(separator: ","))
        }
        return rows.joined(separator: "\n")
    }

    func saveExport(to url: URL) {
        try? exportCSV().write(to: url, atomically: true, encoding: .utf8)
    }

    private func pollEnabledHosts() async {
        await withTaskGroup(of: (UUID, PingResult).self) { group in
            let enabledHosts = hosts.filter(\.enabled)
            for host in enabledHosts {
                group.addTask { [runner] in
                    let result = await runner.ping(address: host.address, timeoutSeconds: Int(self.timeoutSeconds))
                    return (host.id, result)
                }
            }

            for await (id, result) in group {
                if let index = hosts.firstIndex(where: { $0.id == id }) {
                    hosts[index].apply(result: result)
                }
            }
        }
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: storageURL),
              let decoded = try? JSONDecoder().decode([PingHost].self, from: data) else {
            return
        }
        hosts = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(hosts) else { return }
        try? data.write(to: storageURL)
    }

    private func csv(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }

    private func format(_ value: Double?) -> String {
        guard let value else { return "" }
        return String(format: "%.1f", value)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter
    }()

    private static func migrateLegacyStorageIfNeeded(to storageURL: URL, appSupport: URL) {
        guard FileManager.default.fileExists(atPath: storageURL.path) == false else { return }

        let legacyStorageURLs = [
            appSupport.appendingPathComponent("LatencyDeck").appendingPathComponent("hosts.json"),
            appSupport.appendingPathComponent("PingWatch").appendingPathComponent("hosts.json")
        ]

        for legacyURL in legacyStorageURLs where FileManager.default.fileExists(atPath: legacyURL.path) {
            try? FileManager.default.copyItem(at: legacyURL, to: storageURL)
            return
        }
    }
}
