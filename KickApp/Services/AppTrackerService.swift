import AppKit
import Combine
import Foundation

@MainActor
final class AppTrackerService: ObservableObject {
    @Published var trackedApps: [TrackedApp] = []

    /// O(1) lookup by bundle identifier.
    private var indexByBundleId: [String: Set<UUID>] = [:]

    private var cancellable: AnyCancellable?

    init() {
        cancellable = NotificationCenter.default.publisher(
            for: NSWorkspace.didTerminateApplicationNotification,
            object: NSWorkspace.shared
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  let bundleId = app.bundleIdentifier
            else { return }
            self?.removeByBundleId(bundleId)
        }
    }

    func track(_ apps: [TrackedApp]) {
        for app in apps {
            trackedApps.append(app)
            indexByBundleId[app.bundleIdentifier, default: []].insert(app.id)
        }
    }

    func trackedApps(for groupId: UUID) -> [TrackedApp] {
        trackedApps.filter { $0.launchedByGroupId == groupId }
    }

    func terminateAll() {
        for tracked in trackedApps {
            tracked.runningApplication.terminate()
        }
    }

    func terminateGroup(_ groupId: UUID) {
        for tracked in trackedApps where tracked.launchedByGroupId == groupId {
            tracked.runningApplication.terminate()
        }
    }

    var trackedAppCount: Int {
        trackedApps.count
    }

    private func removeByBundleId(_ bundleId: String) {
        guard let ids = indexByBundleId.removeValue(forKey: bundleId) else { return }
        trackedApps.removeAll { ids.contains($0.id) }
    }
}
