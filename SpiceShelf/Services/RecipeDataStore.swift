import Foundation
import SwiftData
import CloudKit
import Combine

/// Manages SwiftData container and provides offline-first recipe persistence with CloudKit sync
@MainActor
final class RecipeDataStore: ObservableObject {
    static let shared = RecipeDataStore()
    
    let modelContainer: ModelContainer
    let modelContext: ModelContext
    
    private let cloudKitService: CloudKitServiceProtocol
    
    @Published var isSyncing: Bool = false
    @Published var lastSyncDate: Date?
    @Published var syncError: Error?
    
    private init(cloudKitService: CloudKitServiceProtocol? = nil) {
        let schema = Schema([CachedRecipe.self, CachedIngredient.self, CachedHowToStep.self, CachedHowToSection.self])
        let modelConfiguration = ModelConfiguration(
            "LocalRecipeStore",
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            groupContainer: .none,
            cloudKitDatabase: .none
        )
        
        do {
            self.modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Schema changed - delete old store and recreate
            print("SwiftData schema error, recreating store: \(error)")
            Self.deleteExistingStore()
            do {
                self.modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Failed to create ModelContainer after reset: \(error)")
            }
        }
        self.modelContext = modelContainer.mainContext
        
        // Avoid circular dependency - use raw CloudKit service directly
        self.cloudKitService = cloudKitService ?? CloudKitService()
        
        // Clean up any corrupted recipes on startup
        cleanupCorruptedRecipes()
    }
    
    // For testing with custom configuration
    init(inMemory: Bool, cloudKitService: CloudKitServiceProtocol? = nil) {
        let schema = Schema([CachedRecipe.self, CachedIngredient.self, CachedHowToStep.self, CachedHowToSection.self])
        let modelConfiguration = ModelConfiguration(
            "LocalRecipeStore",
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            allowsSave: true,
            groupContainer: .none,
            cloudKitDatabase: .none
        )
        
        do {
            self.modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        self.modelContext = modelContainer.mainContext
        
        self.cloudKitService = cloudKitService ?? CloudKitService()
        
        // Clean up any corrupted recipes on startup
        cleanupCorruptedRecipes()
    }
    
    private static func deleteExistingStore() {
        let fileManager = FileManager.default
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
        
        let storeURL = appSupport.appendingPathComponent("LocalRecipeStore.store")
        let shmURL = appSupport.appendingPathComponent("LocalRecipeStore.store-shm")
        let walURL = appSupport.appendingPathComponent("LocalRecipeStore.store-wal")
        
        for url in [storeURL, shmURL, walURL] {
            try? fileManager.removeItem(at: url)
        }
    }
    
    /// Validates and removes recipes that cannot be converted to the current model
    private func cleanupCorruptedRecipes() {
        do {
            let descriptor = FetchDescriptor<CachedRecipe>()
            let allCached = try modelContext.fetch(descriptor)
            var deletedCount = 0
            
            for cached in allCached {
                if !isValidRecipe(cached) {
                    print("Deleting corrupted recipe: \(cached.id) - \(cached.name)")
                    modelContext.delete(cached)
                    deletedCount += 1
                }
            }
            
            if deletedCount > 0 {
                try modelContext.save()
                print("Cleaned up \(deletedCount) corrupted recipe(s)")
            }
        } catch {
            print("Error during recipe cleanup: \(error)")
        }
    }
    
    /// Checks if a cached recipe can be successfully converted to the current Recipe model
    private func isValidRecipe(_ cached: CachedRecipe) -> Bool {
        // Recipe must have a non-empty name
        guard !cached.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        
        // Verify the recipe can be converted without crashing
        // This catches any issues with relationships or data integrity
        let _ = cached.toRecipe()
        
        return true
    }
    
    // MARK: - Local Operations
    
    func fetchAllRecipes() throws -> [Recipe] {
        let pendingDelete = SyncStatus.pendingDelete.rawValue
        let descriptor = FetchDescriptor<CachedRecipe>(
            predicate: #Predicate { $0.syncStatus != pendingDelete },
            sortBy: [SortDescriptor(\.lastModified, order: .reverse)]
        )
        let cachedRecipes = try modelContext.fetch(descriptor)
        return cachedRecipes.map { $0.toRecipe() }
    }
    
    func fetchCachedRecipe(byId id: UUID) throws -> CachedRecipe? {
        let descriptor = FetchDescriptor<CachedRecipe>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    func saveRecipeLocally(_ recipe: Recipe, needsSync: Bool = true) throws {
        if let existing = try fetchCachedRecipe(byId: recipe.id) {
            existing.update(from: recipe)
            existing.needsSync = needsSync
            existing.syncStatus = needsSync ? SyncStatus.pendingUpload.rawValue : SyncStatus.synced.rawValue
        } else {
            let cached = CachedRecipe(from: recipe)
            cached.needsSync = needsSync
            cached.syncStatus = needsSync ? SyncStatus.pendingUpload.rawValue : SyncStatus.synced.rawValue
            modelContext.insert(cached)
        }
        try modelContext.save()
    }
    
    func deleteRecipeLocally(_ recipe: Recipe) throws {
        if let cached = try fetchCachedRecipe(byId: recipe.id) {
            // Mark for deletion sync instead of immediate delete
            cached.needsSync = true
            cached.syncStatus = SyncStatus.pendingDelete.rawValue
            try modelContext.save()
        }
    }
    
    func removeRecipeFromCache(_ recipe: Recipe) throws {
        if let cached = try fetchCachedRecipe(byId: recipe.id) {
            modelContext.delete(cached)
            try modelContext.save()
        }
    }
    
    // MARK: - Sync Operations
    
    func syncWithCloudKit() async {
        guard !isSyncing else { return }
        
        isSyncing = true
        syncError = nil
        
        do {
            // 1. Push local changes to CloudKit
            try await pushPendingChanges()
            
            // 2. Fetch from CloudKit and merge
            try await pullFromCloudKit()
            
            lastSyncDate = Date()
        } catch {
            syncError = error
            print("Sync error: \(error)")
        }
        
        isSyncing = false
    }
    
    private func pushPendingChanges() async throws {
        // Get recipes pending upload
        let uploadDescriptor = FetchDescriptor<CachedRecipe>(
            predicate: {
                let status = SyncStatus.pendingUpload.rawValue
                return #Predicate { $0.syncStatus == status }
            }()
        )
        let toUpload = try modelContext.fetch(uploadDescriptor)
        
        for cached in toUpload {
            let recipe = cached.toRecipe()
            _ = try await cloudKitService.saveRecipe(recipe)
            cached.needsSync = false
            cached.syncStatus = SyncStatus.synced.rawValue
            try? modelContext.save()
        }
        
        // Get recipes pending delete
        let deleteDescriptor = FetchDescriptor<CachedRecipe>(
            predicate: {
                let status = SyncStatus.pendingDelete.rawValue
                return #Predicate { $0.syncStatus == status }
            }()
        )
        let toDelete = try modelContext.fetch(deleteDescriptor)
        
        for cached in toDelete {
            let recipe = cached.toRecipe()
            do {
                try await cloudKitService.deleteRecipe(recipe)
                modelContext.delete(cached)
                try? modelContext.save()
            } catch let error as CKError where error.code == .unknownItem {
                modelContext.delete(cached)
                try? modelContext.save()
            }
        }
    }
    
    private func pullFromCloudKit() async throws {
        let recipes = try await cloudKitService.fetchRecipes()
        
        // Merge remote recipes into local cache
        for recipe in recipes {
            if let existing = try fetchCachedRecipe(byId: recipe.id) {
                // Only update if local isn't pending upload (local changes take precedence)
                if existing.syncStatus == SyncStatus.synced.rawValue {
                    existing.update(from: recipe)
                    existing.needsSync = false
                    existing.syncStatus = SyncStatus.synced.rawValue
                }
            } else {
                let cached = CachedRecipe(from: recipe)
                cached.needsSync = false
                cached.syncStatus = SyncStatus.synced.rawValue
                modelContext.insert(cached)
            }
        }
        
        try modelContext.save()
    }
    
    // MARK: - Image Helpers
    
    func imageData(for recipeId: UUID) -> Data? {
        guard let cached = try? fetchCachedRecipe(byId: recipeId) else { return nil }
        return cached.imageData
    }
    
    func setImageData(_ data: Data?, for recipeId: UUID) throws {
        guard let cached = try fetchCachedRecipe(byId: recipeId) else { return }
        cached.imageData = data
        cached.lastModified = Date()
        cached.needsSync = true
        cached.syncStatus = SyncStatus.pendingUpload.rawValue
        try modelContext.save()
    }
}
