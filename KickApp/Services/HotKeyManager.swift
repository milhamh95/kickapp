import AppKit
import Carbon

/// A recorded keyboard shortcut (modifier flags + key code).
struct HotKeyShortcut: Codable, Hashable, CustomStringConvertible {
    let keyCode: UInt32
    let modifierFlags: UInt32 // Carbon modifier flags

    var description: String {
        var parts: [String] = []
        if modifierFlags & UInt32(controlKey) != 0 { parts.append("\u{2303}") }
        if modifierFlags & UInt32(optionKey) != 0 { parts.append("\u{2325}") }
        if modifierFlags & UInt32(shiftKey) != 0 { parts.append("\u{21E7}") }
        if modifierFlags & UInt32(cmdKey) != 0 { parts.append("\u{2318}") }
        parts.append(keyCodeToString(keyCode))
        return parts.joined()
    }

    /// Convert NSEvent modifier flags to Carbon modifier flags.
    static func carbonFlags(from cocoaFlags: NSEvent.ModifierFlags) -> UInt32 {
        var carbon: UInt32 = 0
        if cocoaFlags.contains(.command) { carbon |= UInt32(cmdKey) }
        if cocoaFlags.contains(.option) { carbon |= UInt32(optionKey) }
        if cocoaFlags.contains(.control) { carbon |= UInt32(controlKey) }
        if cocoaFlags.contains(.shift) { carbon |= UInt32(shiftKey) }
        return carbon
    }

    /// Convert Cocoa NSEvent into a HotKeyShortcut.
    static func from(event: NSEvent) -> HotKeyShortcut {
        HotKeyShortcut(
            keyCode: UInt32(event.keyCode),
            modifierFlags: carbonFlags(from: event.modifierFlags)
        )
    }
}

private let keyCodeMapping: [UInt32: String] = [
        0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
        8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
        16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
        23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
        30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P",
        37: "L", 38: "J", 39: "'", 40: "K", 41: ";", 42: "\\",
        43: ",", 44: "/", 45: "N", 46: "M", 47: ".",
        49: "Space", 50: "`",
        36: "\u{21A9}", // Return
        48: "\u{21E5}", // Tab
        51: "\u{232B}", // Delete
        53: "\u{238B}", // Escape
        96: "F5", 97: "F6", 98: "F7", 99: "F3", 100: "F8",
        101: "F9", 109: "F10", 103: "F11", 111: "F12",
        118: "F4", 120: "F2", 122: "F1",
        123: "\u{2190}", 124: "\u{2192}", 125: "\u{2193}", 126: "\u{2191}",
]

private func keyCodeToString(_ keyCode: UInt32) -> String {
    keyCodeMapping[keyCode] ?? "Key\(keyCode)"
}

// MARK: - HotKeyManager

/// Manages global hotkeys using Carbon's RegisterEventHotKey API.
/// Does NOT require Accessibility permissions.
@MainActor
final class HotKeyManager {
    static let shared = HotKeyManager()

    private var registrations: [UInt32: Registration] = [:]
    private var nextId: UInt32 = 1
    private var eventHandlerRef: EventHandlerRef?

    struct Registration {
        let hotKeyRef: EventHotKeyRef
        let handler: () -> Void
    }

    private init() {
        installEventHandler()
    }

    /// Register a global hotkey. Returns an ID that can be used to unregister.
    func register(shortcut: HotKeyShortcut, handler: @escaping () -> Void) -> UInt32 {
        let id = nextId
        nextId += 1

        let hotKeyId = EventHotKeyID(signature: OSType(0x4B41_5050), id: id) // "KAPP"
        var hotKeyRef: EventHotKeyRef?

        let status = RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.modifierFlags,
            hotKeyId,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if status == noErr, let ref = hotKeyRef {
            registrations[id] = Registration(hotKeyRef: ref, handler: handler)
        }

        return id
    }

    /// Unregister a hotkey by its ID.
    func unregister(id: UInt32) {
        guard let registration = registrations.removeValue(forKey: id) else { return }
        UnregisterEventHotKey(registration.hotKeyRef)
    }

    /// Unregister all hotkeys.
    func unregisterAll() {
        for (_, registration) in registrations {
            UnregisterEventHotKey(registration.hotKeyRef)
        }
        registrations.removeAll()
    }

    private func installEventHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData -> OSStatus in
                guard let event = event, let userData = userData else { return OSStatus(eventNotHandledErr) }

                var hotKeyId = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyId
                )
                guard status == noErr else { return status }

                let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                DispatchQueue.main.async {
                    manager.registrations[hotKeyId.id]?.handler()
                }

                return noErr
            },
            1,
            &eventType,
            selfPtr,
            &eventHandlerRef
        )
    }
}
