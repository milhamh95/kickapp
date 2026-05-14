import Foundation

struct AppGroupApp: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var bundleIdentifier: String
    var path: String

    init(id: UUID = UUID(), name: String, bundleIdentifier: String, path: String) {
        self.id = id
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.path = path
    }
}

struct AppGroup: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var apps: [AppGroupApp]
    var shortcutName: String?
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), name: String, apps: [AppGroupApp] = [], shortcutName: String? = nil) {
        self.id = id
        self.name = name
        self.apps = apps
        self.shortcutName = shortcutName
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
