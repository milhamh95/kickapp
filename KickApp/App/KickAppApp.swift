import SwiftUI

@main
struct KickAppApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()

    var body: some Scene {
        // Menu bar icon — always visible for quick access
        MenuBarExtra("KickApp", systemImage: "bolt.square.fill") {
            MenuBarContentView()
                .environmentObject(appState)
                .environmentObject(appState.trackerService)
        }

        // Settings window — opened from menu bar
        Window("KickApp Settings", id: "settings") {
            MainView()
                .environmentObject(appState)
                .environmentObject(appState.trackerService)
                .environmentObject(appState.discoveryService)
        }
        .defaultSize(width: 800, height: 500)
    }
}

/// Simple menu shown from the menu bar icon.
struct MenuBarContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var trackerService: AppTrackerService
    @Environment(\.openWindow) var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if appState.groups.isEmpty {
                Text("No app groups configured")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                ForEach(appState.groups) { group in
                    Button {
                        appState.launchGroup(group)
                    } label: {
                        HStack {
                            Text(group.name)
                            Spacer()
                            Text("\(group.apps.count) apps")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }
                }
            }

            if !trackerService.trackedApps.isEmpty {
                Divider()
                Button("Close All (\(trackerService.trackedApps.count) running)") {
                    appState.closeAll()
                }
            }

            Divider()

            Button("Settings...") {
                openWindow(id: "settings")
                NSApp.activate(ignoringOtherApps: true)
            }
            .keyboardShortcut(",", modifiers: .command)

            Button("Quit KickApp") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding(4)
    }
}
