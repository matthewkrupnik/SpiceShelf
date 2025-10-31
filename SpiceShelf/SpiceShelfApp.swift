//
//  SpiceShelfApp.swift
//  SpiceShelf
//
//  Created by Matthew Krupnik on 2025-10-24.
//

import SwiftUI
import SwiftData

@main
struct SpiceShelfApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RecipeListView()
        }
        .modelContainer(sharedModelContainer)
    }
}
