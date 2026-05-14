import Foundation

struct SavedConfig: Codable {
    var groups: [AppGroup]
    var launchShortcutMap: [UUID: HotKeyShortcut]
    var closeShortcutMap: [UUID: HotKeyShortcut]

    enum CodingKeys: String, CodingKey {
        case groups, launchShortcutMap, closeShortcutMap
        // Keep old key for migration
        case shortcutMap
    }

    init(
        groups: [AppGroup] = [],
        launchShortcutMap: [UUID: HotKeyShortcut] = [:],
        closeShortcutMap: [UUID: HotKeyShortcut] = [:]
    ) {
        self.groups = groups
        self.launchShortcutMap = launchShortcutMap
        self.closeShortcutMap = closeShortcutMap
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        groups = try container.decode([AppGroup].self, forKey: .groups)

        // Try new key first, fall back to old "shortcutMap" for migration
        let launchMap = (try? container.decode([String: HotKeyShortcut].self, forKey: .launchShortcutMap))
            ?? (try? container.decode([String: HotKeyShortcut].self, forKey: .shortcutMap))
            ?? [:]
        launchShortcutMap = [:]
        for (key, value) in launchMap {
            if let uuid = UUID(uuidString: key) {
                launchShortcutMap[uuid] = value
            }
        }

        let closeMap = (try? container.decode([String: HotKeyShortcut].self, forKey: .closeShortcutMap)) ?? [:]
        closeShortcutMap = [:]
        for (key, value) in closeMap {
            if let uuid = UUID(uuidString: key) {
                closeShortcutMap[uuid] = value
            }
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(groups, forKey: .groups)

        var launchMap: [String: HotKeyShortcut] = [:]
        for (key, value) in launchShortcutMap {
            launchMap[key.uuidString] = value
        }
        try container.encode(launchMap, forKey: .launchShortcutMap)

        var closeMap: [String: HotKeyShortcut] = [:]
        for (key, value) in closeShortcutMap {
            closeMap[key.uuidString] = value
        }
        try container.encode(closeMap, forKey: .closeShortcutMap)
    }
}

final class PersistenceService {
    private let fileManager = FileManager.default

    private var configDirURL: URL {
        let url = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/kickapp", isDirectory: true)
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }

    private var configFileURL: URL {
        configDirURL.appendingPathComponent("config.json")
    }

    func saveConfig(_ config: SavedConfig) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(config) else { return }
        try? data.write(to: configFileURL, options: .atomic)
    }

    func loadConfig() -> SavedConfig {
        guard let data = try? Data(contentsOf: configFileURL) else { return SavedConfig() }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode(SavedConfig.self, from: data)) ?? SavedConfig()
    }
}
