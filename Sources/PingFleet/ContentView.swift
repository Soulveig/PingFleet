import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var monitor: PingMonitor
    @EnvironmentObject private var updater: AppUpdater
    @State private var importing = false
    @State private var exporting = false
    @State private var showingUpdates = false
    @State private var showingDetails = false
    private let toolbarContentWidth: CGFloat = 889
    private let actionButtonSize = CGSize(width: 86, height: 44)

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            hostTable
        }
        .navigationTitle("\(AppInfo.name) \(AppInfo.version)")
        .sheet(isPresented: $monitor.showAddHost) {
            AddHostView()
                .environmentObject(monitor)
        }
        .sheet(isPresented: $monitor.showImportHosts) {
            ImportHostsView(showFileImporter: $importing)
                .environmentObject(monitor)
        }
        .fileImporter(
            isPresented: $importing,
            allowedContentTypes: [.plainText, .commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                monitor.importHosts(from: url)
            }
        }
        .fileExporter(
            isPresented: $exporting,
            document: CSVDocument(text: monitor.exportCSV()),
            contentType: .commaSeparatedText,
            defaultFilename: "pingfleet-export.csv"
        ) { _ in }
        .sheet(isPresented: $showingUpdates) {
            UpdatesView(updater: updater)
        }
        .sheet(isPresented: $showingDetails) {
            HostDetailView(host: monitor.selectedHost)
                .frame(width: 380, height: 520)
        }
        .onAppear {
            updater.checkForUpdatesIfNeeded()
        }
    }

    private var toolbar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                TextField(L10n.filter, text: $monitor.searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: .infinity)

                Picker(L10n.every, selection: $monitor.intervalSeconds) {
                    ForEach([1, 2, 3, 5, 10, 60], id: \.self) { seconds in
                        Text("\(seconds)s")
                            .tag(Double(seconds))
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 150)
                .help(L10n.pingIntervalHelp)
            }
            .frame(width: toolbarContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 10) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        actionButton(
                            title: monitor.isRunning ? L10n.stop : L10n.start,
                            systemImage: monitor.isRunning ? "pause.fill" : "play.fill",
                            prominent: true,
                            help: monitor.isRunning ? L10n.stopHelp : L10n.startHelp
                        ) {
                            monitor.toggleRunning()
                        }

                        actionButton(title: L10n.pingNow, systemImage: "bolt.fill", help: L10n.pingNowHelp) {
                            monitor.pollOnce()
                        }

                        toolbarSeparator

                        actionButton(title: L10n.add, systemImage: "plus", help: L10n.addHelp) {
                            monitor.showAddHost = true
                        }

                        actionButton(title: L10n.remove, systemImage: "minus", help: L10n.removeHelp) {
                            monitor.removeSelectedHost()
                        }
                        .disabled(monitor.selectedHostIDs.isEmpty)

                        actionButton(title: L10n.reset, systemImage: "arrow.counterclockwise", help: L10n.resetHelp) {
                            monitor.resetStats()
                        }

                        toolbarSeparator

                        actionButton(title: L10n.details, systemImage: "sidebar.right", help: L10n.detailsHelp) {
                            showingDetails = true
                        }
                        .disabled(monitor.selectedHostIDs.isEmpty)

                        toolbarSeparator

                        actionButton(title: L10n.importHosts, systemImage: "square.and.arrow.down", help: L10n.importHelp) {
                            monitor.showImportHosts = true
                        }

                        actionButton(title: L10n.export, systemImage: "square.and.arrow.up", help: L10n.exportHelp) {
                            exporting = true
                        }

                        actionButton(title: L10n.update, systemImage: "arrow.triangle.2.circlepath", help: L10n.updatesHelp) {
                            showingUpdates = true
                            updater.checkForUpdates()
                        }
                    }
                    .padding(.vertical, 1)
                    .frame(width: toolbarContentWidth, alignment: .leading)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var toolbarSeparator: some View {
        Divider()
            .frame(width: 1, height: 38)
            .frame(width: 9)
    }

    private func actionButton(title: String, systemImage: String, prominent: Bool = false, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(height: 17)
                Text(title)
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .frame(width: 76)
            }
            .frame(width: actionButtonSize.width, height: actionButtonSize.height)
            .contentShape(Rectangle())
        }
        .frame(width: actionButtonSize.width, height: actionButtonSize.height)
        .buttonStyle(ToolbarActionButtonStyle(size: actionButtonSize, prominent: prominent))
        .help(help)
    }

    private func buttonLabel(_ title: String, systemImage: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
            Text(title)
        }
    }

    private var hostTable: some View {
        Table(monitor.filteredHosts, selection: $monitor.selectedHostIDs) {
            TableColumn("") { host in
                Circle()
                    .fill(color(for: host.state))
                    .frame(width: 10, height: 10)
                    .help(L10n.state(host.state))
            }
            .width(16)

            TableColumn(L10n.name) { host in
                VStack(alignment: .leading, spacing: 2) {
                    Text(host.name)
                        .fontWeight(.medium)
                    Text(host.address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }
            .width(min: 170, ideal: 220)

            TableColumn(L10n.status) { host in
                Text(L10n.state(host.state))
                    .foregroundStyle(color(for: host.state))
            }
            .width(80)

            TableColumn(L10n.last) { host in
                Text(format(host.lastLatencyMilliseconds))
                    .monospacedDigit()
            }
            .width(76)

            TableColumn(L10n.loss) { host in
                Text(String(format: "%.1f%%", host.lossPercent))
                    .monospacedDigit()
            }
            .width(72)

            TableColumn(L10n.sent) { host in
                Text("\(host.sentCount)")
                    .monospacedDigit()
            }
            .width(60)

            TableColumn(L10n.lastCheck) { host in
                Text(host.lastCheckedAt.map(Self.timeFormatter.string) ?? "-")
                    .foregroundStyle(.secondary)
            }
            .width(min: 120, ideal: 150)
        }
    }

    private func color(for state: PingState) -> Color {
        switch state {
        case .unknown: .secondary
        case .online: .green
        case .offline: .red
        }
    }

    private func format(_ value: Double?) -> String {
        guard let value else { return "-" }
        return String(format: "%.1f ms", value)
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter
    }()
}

struct AddHostView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var monitor: PingMonitor
    @State private var name = ""
    @State private var address = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.addHost)
                .font(.title2)
                .fontWeight(.semibold)

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 10) {
                GridRow {
                    Text(L10n.name)
                    TextField("Router", text: $name)
                        .frame(width: 280)
                }
                GridRow {
                    Text(L10n.address)
                    TextField("192.168.1.1", text: $address)
                        .frame(width: 280)
                }
            }

            HStack {
                Spacer()
                Button(L10n.cancel) {
                    dismiss()
                }
                .help(L10n.closeWithoutAdding)
                Button(L10n.add) {
                    monitor.addHost(name: name, address: address)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .help(L10n.addThisHost)
            }
        }
        .padding(20)
        .frame(width: 420)
    }
}

struct ImportHostsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var monitor: PingMonitor
    @Binding var showFileImporter: Bool
    @State private var hostList = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.importList)
                .font(.title2)
                .fontWeight(.semibold)

            Text(L10n.importListPlaceholder)
                .font(.callout)
                .foregroundStyle(.secondary)

            TextEditor(text: $hostList)
                .font(.system(.body, design: .monospaced))
                .frame(width: 520, height: 220)
                .scrollContentBackground(.hidden)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.25))
                )

            HStack {
                Button(L10n.chooseFile) {
                    dismiss()
                    showFileImporter = true
                }

                Spacer()

                Button(L10n.cancel) {
                    dismiss()
                }

                Button(L10n.importFromText) {
                    monitor.importHosts(fromText: hostList)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(hostList.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 560)
    }
}

struct HostDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let host: PingHost?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            if let host {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(host.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text(host.address)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.borderless)
                    .keyboardShortcut(.cancelAction)
                    .help(L10n.cancel)
                }

                latencySparkline(host.history)
                    .frame(height: 112)
                    .padding(.vertical, 6)

                Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 8) {
                    metric(L10n.status, L10n.state(host.state))
                    metric(L10n.last, format(host.lastLatencyMilliseconds))
                    metric(L10n.average, format(host.averageLatencyMilliseconds))
                    metric(L10n.minimum, format(host.minimumLatencyMilliseconds))
                    metric(L10n.maximum, format(host.maximumLatencyMilliseconds))
                    metric(L10n.sent, "\(host.sentCount)")
                    metric(L10n.received, "\(host.receivedCount)")
                    metric(L10n.loss, String(format: "%.1f%%", host.lossPercent))
                }

                if let lastError = host.lastError, !lastError.isEmpty {
                    Text(lastError)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .padding(.top, 4)
                }
            } else {
                ContentUnavailableView(L10n.noHostSelected, systemImage: "network", description: Text(L10n.selectRow))
            }

            Spacer()
        }
        .padding(18)
    }

    private func metric(_ label: String, _ value: String) -> some View {
        GridRow {
            Text(label)
                .foregroundStyle(.secondary)
            Text(value)
                .monospacedDigit()
                .textSelection(.enabled)
        }
    }

    private func latencySparkline(_ samples: [PingSample]) -> some View {
        Canvas { context, size in
            let labelHeight: CGFloat = 18
            let plotRect = CGRect(x: 0, y: 0, width: size.width, height: max(24, size.height - labelHeight))
            context.stroke(Path(plotRect), with: .color(.secondary.opacity(0.25)), lineWidth: 1)

            let visibleSamples = Array(samples.suffix(80))
            let values = visibleSamples.map { $0.latencyMilliseconds ?? 0 }
            guard values.count > 1, let maxValue = values.max(), maxValue > 0 else { return }

            var path = Path()
            for (index, value) in values.enumerated() {
                let x = plotRect.minX + CGFloat(index) / CGFloat(values.count - 1) * plotRect.width
                let normalized = CGFloat(value / maxValue)
                let y = plotRect.maxY - normalized * plotRect.height
                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            context.stroke(path, with: .color(.accentColor), lineWidth: 2)

            let tickIndexes = Array(Set([0, values.count / 2, values.count - 1])).sorted()
            for index in tickIndexes {
                let x = plotRect.minX + CGFloat(index) / CGFloat(values.count - 1) * plotRect.width
                var tickPath = Path()
                tickPath.move(to: CGPoint(x: x, y: plotRect.maxY))
                tickPath.addLine(to: CGPoint(x: x, y: plotRect.maxY + 4))
                context.stroke(tickPath, with: .color(.secondary.opacity(0.45)), lineWidth: 1)

                let label = Self.sparklineTimeFormatter.string(from: visibleSamples[index].date)
                let resolved = context.resolve(Text(label).font(.caption2).foregroundStyle(.secondary))
                let anchor: UnitPoint = {
                    if index == 0 { return .topLeading }
                    if index == values.count - 1 { return .topTrailing }
                    return .top
                }()
                context.draw(resolved, at: CGPoint(x: x, y: plotRect.maxY + 5), anchor: anchor)
            }
        }
    }

    private func format(_ value: Double?) -> String {
        guard let value else { return "-" }
        return String(format: "%.1f ms", value)
    }

    private static let sparklineTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter
    }()
}

struct UpdatesView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var updater: AppUpdater

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: updater.statusIconName)
                    .font(.system(size: 30))
                    .foregroundStyle(updater.statusColor)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.updates)
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text(AppInfo.versionDisplay)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(updater.title)
                    .font(.headline)
                Text(updater.message)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }

            Divider()

            Text(L10n.changelog)
                .font(.headline)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(AppInfo.changelog) { release in
                        VStack(alignment: .leading, spacing: 7) {
                            HStack(spacing: 8) {
                                Text(release.version)
                                    .font(.headline)
                                Text(release.date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            ForEach(release.items, id: \.self) { item in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .foregroundStyle(.secondary)
                                    Text(item)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 170)

            HStack {
                Spacer()
                Button(L10n.cancel) {
                    dismiss()
                }
                Button {
                    updater.checkForUpdates()
                } label: {
                    Label(updater.isChecking ? L10n.checking : L10n.checkNow, systemImage: "arrow.clockwise")
                }
                .disabled(updater.isChecking || updater.isInstalling)

                if updater.updateAvailable {
                    Button {
                        updater.installUpdate()
                    } label: {
                        Label(updater.isInstalling ? L10n.installing : L10n.installUpdate, systemImage: "arrow.down.circle")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(updater.isInstalling)
                }
            }
        }
        .padding(20)
        .frame(minWidth: 520, idealWidth: 520, minHeight: 260)
    }
}

private struct ToolbarActionButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    let size: CGSize
    let prominent: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: size.width, height: size.height)
            .foregroundStyle(foregroundColor)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(backgroundColor(configuration: configuration))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(.white.opacity(isEnabled ? 0.14 : 0.06), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.82 : 1)
    }

    private var foregroundColor: Color {
        if prominent && isEnabled {
            return .white
        }

        return isEnabled ? .primary : .secondary.opacity(0.5)
    }

    private func backgroundColor(configuration: Configuration) -> Color {
        if prominent {
            return .accentColor.opacity(isEnabled ? (configuration.isPressed ? 0.72 : 0.9) : 0.24)
        }

        return Color(nsColor: .controlColor)
            .opacity(isEnabled ? (configuration.isPressed ? 0.72 : 0.92) : 0.42)
    }
}

struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }

    var text: String

    init(text: String) {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        text = ""
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}
