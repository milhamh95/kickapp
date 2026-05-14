import Combine
import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var groups: [AppGroup] = []
    @Published var selectedGroupId: UUID?
    @Published var launchShortcutMap: [UUID: HotKeyShortcut] = [:]
    @Published var closeShortcutMap: [UUID: HotKeyShortcut] = [:]

    let launcherService = AppLauncherService()
    let shortcutService = ShortcutService()
    let discoveryService = AppDiscoveryService()
    let persistenceService = PersistenceService()

    /// Tracks bundle IDs launched per group so close shortcut knows what to quit.
    private var launchedBundleIds: [UUID: Set<String>] = [:]

    private var cancellables = Set<AnyCancellable>()

    init() {
        let saved = persistenceService.loadConfig()
        groups = saved.groups
        launchShortcutMap = saved.launchShortcutMap
        closeShortcutMap = saved.closeShortcutMap
        registerShortcuts()

        $groups
            .combineLatest($launchShortcutMap, $closeShortcutMap)
            .dropFirst()
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] groups, launchMap, closeMap in
                self?.persistenceService.saveConfig(
                    SavedConfig(groups: groups, launchShortcutMap: launchMap, closeShortcutMap: closeMap)
                )
            }
            .store(in: &cancellables)
    }

    // MARK: - Group Management

    func addGroup(_ group: AppGroup) {
        groups.append(group)
    }

    func updateGroup(_ group: AppGroup) {
        if let index = groups.firstIndex(where: { $0.id == group.id }) {
            var updated = group
            updated.updatedAt = Date()
            groups[index] = updated
        }
    }

    func deleteGroup(_ group: AppGroup) {
        launchShortcutMap.removeValue(forKey: group.id)
        closeShortcutMap.removeValue(forKey: group.id)
        launchedBundleIds.removeValue(forKey: group.id)
        groups.removeAll { $0.id == group.id }
        if selectedGroupId == group.id {
            selectedGroupId = groups.first?.id
        }
        registerShortcuts()
    }

    // MARK: - Shortcuts

    func setLaunchShortcut(_ shortcut: HotKeyShortcut?, for groupId: UUID) {
        launchShortcutMap[groupId] = shortcut
        registerShortcuts()
    }

    func setCloseShortcut(_ shortcut: HotKeyShortcut?, for groupId: UUID) {
        closeShortcutMap[groupId] = shortcut
        registerShortcuts()
    }

    private func registerShortcuts() {
        shortcutService.registerShortcuts(
            for: groups,
            launchHandler: { [weak self] group in
                self?.launchGroup(group)
            },
            closeHandler: { [weak self] groupId in
                self?.closeGroup(groupId)
            },
            launchShortcutMap: launchShortcutMap,
            closeShortcutMap: closeShortcutMap
        )
    }

    // MARK: - Launching

    func launchGroup(_ group: AppGroup) {
        Task {
            let launched = await launcherService.launchGroup(group)
            launchedBundleIds[group.id] = Set(launched.map(\.bundleIdentifier))
        }
    }

    func closeGroup(_ groupId: UUID) {
        guard let bundleIds = launchedBundleIds[groupId] else { return }
        let workspace = NSWorkspace.shared
        for app in workspace.runningApplications {
            if let bundleId = app.bundleIdentifier, bundleIds.contains(bundleId) {
                app.terminate()
            }
        }
        launchedBundleIds.removeValue(forKey: groupId)
    }
}
