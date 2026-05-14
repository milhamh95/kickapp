import Foundation

final class LaunchAgentService {
    private let bundleId = "com.kickapp.KickApp"
    private let fileManager = FileManager.default

    private var launchAgentDir: URL {
        fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents", isDirectory: true)
    }

    private var plistURL: URL {
        launchAgentDir.appendingPathComponent("\(bundleId).plist")
    }

    var isEnabled: Bool {
        fileManager.fileExists(atPath: plistURL.path)
    }

    func enable() async -> Bool {
        guard let executablePath = Bundle.main.executablePath ?? findExecutablePath() else {
            return false
        }

        let plistContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>\(bundleId)</string>
            <key>ProgramArguments</key>
            <array>
                <string>\(executablePath)</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <false/>
            <key>ProcessType</key>
            <string>Interactive</string>
        </dict>
        </plist>
        """

        let url = plistURL
        let dir = launchAgentDir

        return await Task.detached {
            do {
                try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
                try plistContent.write(to: url, atomically: true, encoding: .utf8)
                try Self.runLaunchctl(["load", url.path])
                return true
            } catch {
                return false
            }
        }.value
    }

    func disable() async -> Bool {
        guard fileManager.fileExists(atPath: plistURL.path) else { return true }
        let url = plistURL

        return await Task.detached {
            do {
                try Self.runLaunchctl(["unload", url.path])
                try FileManager.default.removeItem(at: url)
                return true
            } catch {
                return false
            }
        }.value
    }

    private static func runLaunchctl(_ arguments: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = arguments
        try process.run()
        process.waitUntilExit()
    }

    private func findExecutablePath() -> String? {
        let appPath = "/Applications/KickApp.app/Contents/MacOS/KickApp"
        if fileManager.fileExists(atPath: appPath) {
            return appPath
        }
        return ProcessInfo.processInfo.arguments.first
    }
}
