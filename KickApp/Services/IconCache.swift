import AppKit

/// Thread-safe icon cache using NSCache (auto-evicts under memory pressure).
final class IconCache {
    static let shared = IconCache()

    private let cache = NSCache<NSString, NSImage>()

    private init() {
        cache.countLimit = 200
    }

    func icon(forPath path: String) -> NSImage {
        let key = path as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }
        let icon = NSWorkspace.shared.icon(forFile: path)
        icon.size = NSSize(width: 32, height: 32)
        cache.setObject(icon, forKey: key)
        return icon
    }

    func icon(forBundleIdentifier bundleId: String) -> NSImage {
        let key = bundleId as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }
        let path = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId)?.path ?? ""
        let icon = NSWorkspace.shared.icon(forFile: path)
        icon.size = NSSize(width: 32, height: 32)
        cache.setObject(icon, forKey: key)
        return icon
    }
}
