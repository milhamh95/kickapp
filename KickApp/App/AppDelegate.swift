import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // App runs as a background agent (LSUIElement).
        // No dock icon — the menu bar icon is the entry point.
    }
}
