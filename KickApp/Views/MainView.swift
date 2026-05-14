import SwiftUI

struct MainView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            AppGroupsTab()
                .tabItem {
                    Label("App Groups", systemImage: "rectangle.stack")
                }
        }
        .frame(minWidth: 700, minHeight: 450)
    }
}

struct AppGroupsTab: View {
    @EnvironmentObject var appState: AppState
    @State private var showingAddGroup = false

    var body: some View {
        NavigationSplitView {
            SidebarView(showingAddGroup: $showingAddGroup)
        } detail: {
            if let selectedId = appState.selectedGroupId,
               let group = appState.groups.first(where: { $0.id == selectedId }) {
                AppGroupEditorView(group: group)
            } else {
                ContentUnavailableView(
                    "No Group Selected",
                    systemImage: "rectangle.stack",
                    description: Text("Select a group from the sidebar or create a new one.")
                )
            }
        }
        .sheet(isPresented: $showingAddGroup) {
            AddGroupSheet()
        }
    }
}

struct SidebarView: View {
    @EnvironmentObject var appState: AppState
    @Binding var showingAddGroup: Bool

    var body: some View {
        List(selection: $appState.selectedGroupId) {
            Section("App Groups") {
                ForEach(appState.groups) { group in
                    GroupRow(group: group)
                        .tag(group.id)
                        .contextMenu {
                            Button("Launch") {
                                appState.launchGroup(group)
                            }
                            Button("Close") {
                                appState.closeGroup(group.id)
                            }
                            Divider()
                            Button("Delete", role: .destructive) {
                                appState.deleteGroup(group)
                            }
                        }
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddGroup = true
                } label: {
                    Label("Add Group", systemImage: "plus")
                }
            }
        }
    }
}

struct GroupRow: View {
    let group: AppGroup
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(group.name)
                    .font(.headline)
                Text("\(group.apps.count) app\(group.apps.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                appState.launchGroup(group)
            } label: {
                Image(systemName: "play.fill")
            }
            .buttonStyle(.borderless)
            .help("Launch all apps in this group")
        }
        .padding(.vertical, 2)
    }
}

struct AddGroupSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var name = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("New App Group")
                .font(.headline)

            TextField("Group Name", text: $name)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Create") {
                    let group = AppGroup(name: name)
                    appState.addGroup(group)
                    appState.selectedGroupId = group.id
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 300)
    }
}
