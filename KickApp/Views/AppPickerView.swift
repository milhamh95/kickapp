import SwiftUI

struct AppPickerView: View {
    let group: AppGroup
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var discoveryService: AppDiscoveryService
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var selectedBundleIds: Set<String> = []

    private var filteredApps: [DiscoveredApp] {
        let apps = searchText.isEmpty ? discoveryService.discoveredApps : discoveryService.search(query: searchText)
        let existingIds = Set(group.apps.map(\.bundleIdentifier))
        return apps.filter { !existingIds.contains($0.bundleIdentifier) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Add Apps to \"\(group.name)\"")
                    .font(.headline)
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Add Selected (\(selectedBundleIds.count))") {
                    addSelectedApps()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selectedBundleIds.isEmpty)
            }
            .padding()

            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search apps...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal)

            List(filteredApps, selection: $selectedBundleIds) { app in
                HStack {
                    Image(nsImage: IconCache.shared.icon(forPath: app.path.path))
                        .resizable()
                        .frame(width: 32, height: 32)
                    VStack(alignment: .leading) {
                        Text(app.name)
                            .font(.body)
                        Text(app.bundleIdentifier)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .tag(app.bundleIdentifier)
                .padding(.vertical, 2)
            }
        }
        .frame(width: 500, height: 400)
        .onAppear {
            if discoveryService.discoveredApps.isEmpty {
                discoveryService.discoverApps()
            }
        }
    }

    private func addSelectedApps() {
        var updated = group
        for bundleId in selectedBundleIds {
            // O(1) lookup via indexed dictionary
            if let discoveredApp = discoveryService.appsByBundleId[bundleId] {
                let app = AppGroupApp(
                    name: discoveredApp.name,
                    bundleIdentifier: discoveredApp.bundleIdentifier,
                    path: discoveredApp.path.path
                )
                updated.apps.append(app)
            }
        }
        appState.updateGroup(updated)
    }
}
