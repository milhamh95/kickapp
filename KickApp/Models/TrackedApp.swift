import AppKit
import Foundation

struct TrackedApp: Identifiable, Hashable {
    let id: UUID
    let bundleIdentifier: String
    let name: String
    let runningApplication: NSRunningApplication
    let launchedByGroupId: UUID
    let launchedAt: Date

    init(
        bundleIdentifier: String,
        name: String,
        runningApplication: NSRunningApplication,
        launchedByGroupId: UUID
    ) {
        self.id = UUID()
        self.bundleIdentifier = bundleIdentifier
        self.name = name
        self.runningApplication = runningApplication
        self.launchedByGroupId = launchedByGroupId
        self.launchedAt = Date()
    }

    static func == (lhs: TrackedApp, rhs: TrackedApp) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
