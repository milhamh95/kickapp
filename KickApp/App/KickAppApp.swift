import AppKit
import SwiftUI

/// Loads the menu bar icon from the app bundle's Resources directory.
func loadMenuBarIcon() -> NSImage? {
    // Try multiple paths to find the Resources directory
    let candidates: [URL] = [
        Bundle.main.bundleURL.appendingPathComponent("Contents/Resources"),
        Bundle.main.resourceURL,
        URL(fileURLWithPath: ProcessInfo.processInfo.arguments[0])
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Resources"),
    ].compactMap { $0 }

    var iconPath: String?
    var icon2xPath: String?
    for dir in candidates {
        let p = dir.appendingPathComponent("MenuBarIcon.png").path
        if FileManager.default.fileExists(atPath: p) {
            iconPath = p
            icon2xPath = dir.appendingPathComponent("MenuBarIcon@2x.png").path
            break
        }
    }

    guard let iconPath, let image1x = NSImage(contentsOfFile: iconPath) else {
        return nil
    }

    let combined = NSImage(size: NSSize(width: 18, height: 18))
    if let rep1x = image1x.representations.first {
        combined.addRepresentation(rep1x)
    }
    if let icon2xPath, let image2x = NSImage(contentsOfFile: icon2xPath),
       let rep2x = image2x.representations.first {
        combined.addRepresentation(rep2x)
    }

    combined.isTemplate = false
    return combined
}

private let menuBarIcon: NSImage? = loadMenuBarIcon()

@main
struct KickAppApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView()
                .environmentObject(appState)
        } label: {
            if let icon = menuBarIcon {
                Image(nsImage: icon)
            } else {
                Image(systemName: "sportscourt.circle")
            }
        }

        Window("KickApp Settings", id: "settings") {
            MainView()
                .environmentObject(appState)
                .environmentObject(appState.discoveryService)
        }
        .defaultSize(width: 800, height: 500)
    }
}

struct MenuBarContentView: View {
    @EnvironmentObject var appState: AppState
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
