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

    init() {
        // Simple check for CloudKit availability to log status
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
            TabView {
                Tab("Recipes", systemImage: "book") {
                    RecipeListView()
                }
                Tab("Settings", systemImage: "gearshape") {
                    SettingsView()
                }
            }
            .modelContainer(dataStore.modelContainer)
        }
    }
}
