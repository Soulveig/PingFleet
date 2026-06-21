import Foundation

enum PingState: String, Codable, CaseIterable {
    case unknown
    case online
    case offline

    var title: String {
        switch self {
        case .unknown: "Unknown"
        case .online: "Online"
        case .offline: "Offline"
        }
    }
}

struct PingSample: Codable {
    let date: Date
    let latencyMilliseconds: Double?
}

struct PingHost: Identifiable, Codable {
    let id: UUID
    var name: String
    var address: String
    var enabled: Bool
    var state: PingState
    var lastLatencyMilliseconds: Double?
    var minimumLatencyMilliseconds: Double?
    var maximumLatencyMilliseconds: Double?
    var sentCount: Int
    var receivedCount: Int
    var lastCheckedAt: Date?
    var lastError: String?
    var history: [PingSample]

    init(name: String, address: String) {
        self.id = UUID()
        self.name = name.isEmpty ? address : name
        self.address = address
        self.enabled = true
        self.state = .unknown
        self.lastLatencyMilliseconds = nil
        self.minimumLatencyMilliseconds = nil
        self.maximumLatencyMilliseconds = nil
        self.sentCount = 0
        self.receivedCount = 0
        self.lastCheckedAt = nil
        self.lastError = nil
        self.history = []
    }

    var lossPercent: Double {
        guard sentCount > 0 else { return 0 }
        return Double(sentCount - receivedCount) / Double(sentCount) * 100
    }

    var averageLatencyMilliseconds: Double? {
        let values = history.compactMap(\.latencyMilliseconds)
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    mutating func apply(result: PingResult) {
        sentCount += 1
        lastCheckedAt = Date()
        lastError = result.errorMessage
        history.append(PingSample(date: Date(), latencyMilliseconds: result.latencyMilliseconds))
        if history.count > 300 {
            history.removeFirst(history.count - 300)
        }

        if let latency = result.latencyMilliseconds {
            receivedCount += 1
            state = .online
            lastLatencyMilliseconds = latency
            minimumLatencyMilliseconds = min(minimumLatencyMilliseconds ?? latency, latency)
            maximumLatencyMilliseconds = max(maximumLatencyMilliseconds ?? latency, latency)
        } else {
            state = .offline
            lastLatencyMilliseconds = nil
        }
    }

    mutating func resetStats() {
        state = .unknown
        lastLatencyMilliseconds = nil
        minimumLatencyMilliseconds = nil
        maximumLatencyMilliseconds = nil
        sentCount = 0
        receivedCount = 0
        lastCheckedAt = nil
        lastError = nil
        history.removeAll()
    }
}
