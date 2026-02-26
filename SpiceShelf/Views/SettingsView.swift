import SwiftUI

struct SettingsView: View {

    @ObservedObject private var dataStore = RecipeDataStore.shared

    var body: some View {
        NavigationStack {
            List {
                Section("iCloud Sync") {
                    HStack {
                        Label("Status", systemImage: dataStore.isSyncing ? "arrow.triangle.2.circlepath" : "checkmark.icloud")
                        Spacer()
                        if dataStore.isSyncing {
                            ProgressView()
                        } else {
                            Text("Up to date")
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let lastSync = dataStore.lastSyncDate {
                        LabeledContent("Last Synced", value: lastSync, format: .dateTime)
                    }

                    if let error = dataStore.syncError {
                        Label(error.localizedDescription, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }

                    Button {
                        Task { await dataStore.syncWithCloudKit() }
                    } label: {
                        Label("Sync Now", systemImage: "arrow.clockwise")
                    }
                    .disabled(dataStore.isSyncing)
                }

                Section("About") {
                    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
                    LabeledContent("Build", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
