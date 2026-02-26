//
//  SpiceShelfApp.swift
//  SpiceShelf
//
//  Created by Matthew Krupnik on 2025-10-24.
//

import SwiftUI
import SwiftData
import CloudKit

@main
struct SpiceShelfApp: App {
    
    let dataStore = RecipeDataStore.shared
    @State private var pendingImportURL: String?
    @State private var pendingURLQueue: [String] = []
    @Environment(\.scenePhase) private var scenePhase

    init() {
        CKContainer.default().accountStatus { status, error in
            if let error = error {
                print("CK accountStatus error: \(error.localizedDescription)")
            } else {
                switch status {
                case .available:
                    print("iCloud account available")
                default:
                    print("iCloud account not available or restricted")
                }
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            RecipeListView()
                .modelContainer(dataStore.modelContainer)
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
                .sheet(item: $pendingImportURL) { recipeURL in
                    ImportRecipeView(initialURL: recipeURL)
                        .presentationBackground(.regularMaterial)
                        .presentationCornerRadius(24)
                }
                .onChange(of: pendingImportURL) { oldValue, newValue in
                    if newValue == nil, !pendingURLQueue.isEmpty {
                        pendingImportURL = pendingURLQueue.removeFirst()
                    }
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        checkForSharedURL()
                    }
                }
                .onAppear {
                    checkForSharedURL()
                }
        }
    }

    private func handleIncomingURL(_ url: URL) {
        guard url.scheme == "spiceshelf",
              url.host == "import",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let urlParam = components.queryItems?.first(where: { $0.name == "url" })?.value else {
            return
        }
        pendingImportURL = urlParam
    }

    private func checkForSharedURL() {
        guard let defaults = UserDefaults(suiteName: "group.mk.lan.SpiceShelf"),
              let urls = defaults.stringArray(forKey: "pendingImportURLs"),
              !urls.isEmpty else {
            return
        }
        defaults.removeObject(forKey: "pendingImportURLs")
        defaults.synchronize()
        var queue = urls
        pendingImportURL = queue.removeFirst()
        pendingURLQueue = queue
    }
}

extension String: @retroactive Identifiable {
    public var id: String { self }
}
