import Foundation

/// Lightweight model — no NSImage stored. Icons are loaded on-demand via IconCache.
struct DiscoveredApp: Identifiable, Hashable {
    let id: String
    let name: String
    let bundleIdentifier: String
    let path: URL

    static func == (lhs: DiscoveredApp, rhs: DiscoveredApp) -> Bool {
        lhs.bundleIdentifier == rhs.bundleIdentifier
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(bundleIdentifier)
    }
}
