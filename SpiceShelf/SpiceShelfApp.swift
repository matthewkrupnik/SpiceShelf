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
    // Will be initialized in init() after we determine iCloud availability.
    var sharedModelContainer: ModelContainer!

    init() {
        let semaphore = DispatchSemaphore(value: 0)
        var accountAvailable = false

        CKContainer.default().accountStatus { status, error in
            if let error = error {
                print("CK accountStatus error: \(error.localizedDescription). Proceeding without CloudKit mirroring.")
                accountAvailable = false
            } else {
                switch status {
                case .available:
                    accountAvailable = true
                default:
                    accountAvailable = false
                }
            }
            semaphore.signal()
        }

        // Wait briefly (up to 2 seconds) for account status. If the check times out,
        // we'll proceed without assuming an iCloud account is available.
        let timeoutResult = semaphore.wait(timeout: .now() + 2.0)
        if timeoutResult == .timedOut {
            print("CK accountStatus check timed out — proceeding without CloudKit mirroring.")
            accountAvailable = false
        }

        if accountAvailable {
            print("iCloud account available — proceeding with potential CloudKit mirroring.")
        } else {
            print("iCloud account not available — CloudKit mirroring will be disabled for this run.")
        }

        // Create the ModelContainer now that we've determined account status.
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            sharedModelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RecipeListView()
        }
        .modelContainer(sharedModelContainer)
    }
}
