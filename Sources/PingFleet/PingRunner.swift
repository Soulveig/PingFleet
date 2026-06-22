import Foundation

struct PingResult {
    let latencyMilliseconds: Double?
    let errorMessage: String?
}

actor PingRunner {
    func ping(address: String, timeoutSeconds: Int) async -> PingResult {
        let address = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !address.hasPrefix("-") else {
            return PingResult(latencyMilliseconds: nil, errorMessage: "Invalid host")
        }

        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/sbin/ping")
        process.arguments = ["-c", "1", "-W", String(timeoutSeconds * 1000), address]
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
        } catch {
            return PingResult(latencyMilliseconds: nil, errorMessage: error.localizedDescription)
        }

        return await withCheckedContinuation { continuation in
            process.terminationHandler = { finishedProcess in
                let output = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                let error = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

                if finishedProcess.terminationStatus == 0, let latency = Self.parseLatency(from: output) {
                    continuation.resume(returning: PingResult(latencyMilliseconds: latency, errorMessage: nil))
                } else {
                    let message = Self.shortError(from: output + "\n" + error)
                    continuation.resume(returning: PingResult(latencyMilliseconds: nil, errorMessage: message))
                }
            }
        }
    }

    private static func parseLatency(from output: String) -> Double? {
        guard let range = output.range(of: "time=") else { return nil }
        let suffix = output[range.upperBound...]
        let value = suffix.prefix { character in
            character.isNumber || character == "."
        }
        return Double(value)
    }

    private static func shortError(from output: String) -> String {
        let trimmedLines = output
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if let firstFailure = trimmedLines.first(where: { line in
            line.localizedCaseInsensitiveContains("unknown host") ||
            line.localizedCaseInsensitiveContains("timeout") ||
            line.localizedCaseInsensitiveContains("cannot resolve") ||
            line.localizedCaseInsensitiveContains("no route")
        }) {
            return firstFailure
        }

        return trimmedLines.first ?? "No reply"
    }
}
