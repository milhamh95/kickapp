import AppKit
import Foundation

@MainActor
final class AppDiscoveryService: ObservableObject {
    @Published var discoveredApps: [DiscoveredApp] = []

    /// Indexed by bundleIdentifier for O(1) lookups.
    private(set) var appsByBundleId: [String: DiscoveredApp] = [:]

    private let searchPaths = [
        "/Applications",
        "/System/Applications",
        "/Applications/Utilities",
        "/System/Applications/Utilities",
    ]

    func discoverApps() {
        // Run filesystem scanning off the main thread
        Task.detached { [searchPaths] in
            let apps = Self.scanApps(searchPaths: searchPaths)
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.discoveredApps = apps
                self.appsByBundleId = Dictionary(uniqueKeysWithValues: apps.map { ($0.bundleIdentifier, $0) })
            }
        }
    }

    private nonisolated static func scanApps(searchPaths: [String]) -> [DiscoveredApp] {
        var apps: [String: DiscoveredApp] = [:]
        let fileManager = FileManager.default

        var allPaths = searchPaths
        let homeApps = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Applications").path
        allPaths.append(homeApps)

        for searchPath in allPaths {
            let url = URL(fileURLWithPath: searchPath)
            guard let contents = try? fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isApplicationKey],
                options: [.skipsHiddenFiles]
            ) else { continue }

            for itemURL in contents {
                guard itemURL.pathExtension == "app" else { continue }
                if let app = makeDiscoveredApp(from: itemURL), apps[app.bundleIdentifier] == nil {
                    apps[app.bundleIdentifier] = app
                }
            }
        }

        return apps.values.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private nonisolated static func makeDiscoveredApp(from url: URL) -> DiscoveredApp? {
        guard let bundle = Bundle(url: url),
              let bundleIdentifier = bundle.bundleIdentifier
        else { return nil }

        let name = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? url.deletingPathExtension().lastPathComponent

        return DiscoveredApp(
            id: bundleIdentifier,
            name: name,
            bundleIdentifier: bundleIdentifier,
            path: url
        )
    }

    func search(query: String) -> [DiscoveredApp] {
        guard !query.isEmpty else { return discoveredApps }
        let lowered = query.lowercased()
        return discoveredApps.filter {
            $0.name.lowercased().contains(lowered) ||
            $0.bundleIdentifier.lowercased().contains(lowered)
        }
    }
}
