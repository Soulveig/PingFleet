import SwiftUI

@main
struct PingFleetApp: App {
    @StateObject private var monitor = PingMonitor()
    @StateObject private var updater = AppUpdater()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(monitor)
                .environmentObject(updater)
                .frame(minWidth: 913, idealWidth: 913, maxWidth: 913, minHeight: 600)
        }
        .defaultSize(width: 913, height: 600)
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button(L10n.addHost) {
                    monitor.showAddHost = true
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
        }
    }
}
