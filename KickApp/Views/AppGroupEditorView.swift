import SwiftUI

struct AppGroupEditorView: View {
    let group: AppGroup
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var trackerService: AppTrackerService
    @State private var editedName: String = ""
    @State private var showingAppPicker = false

    private var launchShortcut: Binding<HotKeyShortcut?> {
        Binding(
            get: { appState.launchShortcutMap[group.id] },
            set: { appState.setLaunchShortcut($0, for: group.id) }
        )
    }

    private var closeShortcut: Binding<HotKeyShortcut?> {
        Binding(
            get: { appState.closeShortcutMap[group.id] },
            set: { appState.setCloseShortcut($0, for: group.id) }
        )
    }

    var body: some View {
        Form {
            Section("Group Settings") {
                TextField("Name", text: $editedName)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        var updated = group
                        updated.name = editedName
                        appState.updateGroup(updated)
                    }

                ShortcutRecorderView(
                    label: "Launch Shortcut",
                    shortcut: launchShortcut
                )

                ShortcutRecorderView(
                    label: "Close Shortcut",
                    shortcut: closeShortcut
                )
            }

            Section("Apps (\(group.apps.count))") {
                if group.apps.isEmpty {
                    ContentUnavailableView(
                        "No Apps",
                        systemImage: "app.dashed",
                        description: Text("Add apps to this group to launch them together.")
                    )
                } else {
                    ForEach(group.apps) { app in
                        HStack {
                            Image(nsImage: IconCache.shared.icon(forPath: app.path))
                                .resizable()
                                .frame(width: 24, height: 24)
                            VStack(alignment: .leading) {
                                Text(app.name)
                                    .font(.body)
                                Text(app.bundleIdentifier)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button {
                                removeApp(app)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(.vertical, 2)
                    }
                }

                Button {
                    showingAppPicker = true
                } label: {
                    Label("Add Apps...", systemImage: "plus")
                }
            }

            Section {
                HStack {
                    Button {
                        appState.launchGroup(group)
                    } label: {
                        Label("Launch All", systemImage: "play.fill")
                    }
                    .controlSize(.large)

                    let groupTracked = trackerService.trackedApps(for: group.id)
                    if !groupTracked.isEmpty {
                        Button {
                            appState.closeGroup(group.id)
                        } label: {
                            Label("Close Group Apps (\(groupTracked.count))", systemImage: "xmark.circle")
                        }
                        .controlSize(.large)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            editedName = group.name
        }
        .onChange(of: group.id) {
            editedName = group.name
        }
        .sheet(isPresented: $showingAppPicker) {
            AppPickerView(group: group)
        }
    }

    private func removeApp(_ app: AppGroupApp) {
        var updated = group
        updated.apps.removeAll { $0.id == app.id }
        appState.updateGroup(updated)
    }
}
