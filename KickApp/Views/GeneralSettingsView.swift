import SwiftUI

struct GeneralSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var launchAtLogin: Bool = false
    private let launchAgentService = LaunchAgentService()

    var body: some View {
        Form {
            Section("Startup") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        Task {
                            if newValue {
                                let success = await launchAgentService.enable()
                                if !success { launchAtLogin = false }
                            } else {
                                _ = await launchAgentService.disable()
                            }
                        }
                    }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            launchAtLogin = launchAgentService.isEnabled
        }
    }
}
