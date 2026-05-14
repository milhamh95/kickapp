import AppKit
import Foundation

@MainActor
final class AppLauncherService {

    func launchGroup(_ group: AppGroup) async -> [TrackedApp] {
        var trackedApps: [TrackedApp] = []

        for (index, app) in group.apps.enumerated() {
            let appURL = URL(fileURLWithPath: app.path)
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = (index == group.apps.count - 1) // only activate the last app

            do {
                let runningApp = try await NSWorkspace.shared.openApplication(
                    at: appURL,
                    configuration: configuration
                )
                let tracked = TrackedApp(
                    bundleIdentifier: app.bundleIdentifier,
                    name: app.name,
                    runningApplication: runningApp,
                    launchedByGroupId: group.id
                )
                trackedApps.append(tracked)
            } catch {
                print("Failed to launch \(app.name): \(error.localizedDescription)")
            }
        }

        return trackedApps
    }
}
