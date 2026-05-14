import Foundation

@MainActor
final class ShortcutService {
    private var registeredIds: [UInt32] = []

    func registerShortcuts(
        for groups: [AppGroup],
        launchHandler: @escaping (AppGroup) -> Void,
        closeHandler: @escaping (UUID) -> Void,
        launchShortcutMap: [UUID: HotKeyShortcut],
        closeShortcutMap: [UUID: HotKeyShortcut]
    ) {
        unregisterAll()

        let manager = HotKeyManager.shared

        for group in groups {
            // Register launch shortcut
            if let shortcut = launchShortcutMap[group.id] {
                let id = manager.register(shortcut: shortcut) {
                    launchHandler(group)
                }
                registeredIds.append(id)
            }

            // Register close shortcut
            if let shortcut = closeShortcutMap[group.id] {
                let groupId = group.id
                let id = manager.register(shortcut: shortcut) {
                    closeHandler(groupId)
                }
                registeredIds.append(id)
            }
        }
    }

    func unregisterAll() {
        let manager = HotKeyManager.shared
        for id in registeredIds {
            manager.unregister(id: id)
        }
        registeredIds.removeAll()
    }
}
