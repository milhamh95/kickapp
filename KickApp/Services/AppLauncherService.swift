import AppKit
import Foundation

struct LaunchedApp {
    let bundleIdentifier: String
}

@MainActor
final class AppLauncherService {

    func launchGroup(_ group: AppGroup) async -> [LaunchedApp] {
        var launched: [LaunchedApp] = []

        for (index, app) in group.apps.enumerated() {
            let appURL = URL(fileURLWithPath: app.path)
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = (index == group.apps.count - 1)

            do {
                _ = try await NSWorkspace.shared.openApplication(
                    at: appURL,
                    configuration: configuration
                )
                launched.append(LaunchedApp(bundleIdentifier: app.bundleIdentifier))
            } catch {
                print("Failed to launch \(app.name): \(error.localizedDescription)")
            }
        }

        return launched
    }
}
