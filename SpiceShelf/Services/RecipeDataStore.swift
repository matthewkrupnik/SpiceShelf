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
        let schema = Schema([CachedRecipe.self, CachedIngredient.self])
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
    }
    
    // For testing with custom configuration
    init(inMemory: Bool, cloudKitService: CloudKitServiceProtocol? = nil) {
        let schema = Schema([CachedRecipe.self, CachedIngredient.self])
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
    }
    
    private static func deleteExistingStore() {
        let fileManager = FileManager.default
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
        
        let storeURL = appSupport.appendingPathComponent("default.store")
        let shmURL = appSupport.appendingPathComponent("default.store-shm")
        let walURL = appSupport.appendingPathComponent("default.store-wal")
        
        for url in [storeURL, shmURL, walURL] {
            try? fileManager.removeItem(at: url)
        }
    }
    
    // MARK: - Local Operations
    
    func fetchAllRecipes() throws -> [Recipe] {
        let descriptor = FetchDescriptor<CachedRecipe>(
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
            existing.syncStatus = needsSync ? "pendingUpload" : "synced"
        } else {
            let cached = CachedRecipe(from: recipe)
            cached.needsSync = needsSync
            cached.syncStatus = needsSync ? "pendingUpload" : "synced"
            modelContext.insert(cached)
        }
        try modelContext.save()
    }
    
    func deleteRecipeLocally(_ recipe: Recipe) throws {
        if let cached = try fetchCachedRecipe(byId: recipe.id) {
            // Mark for deletion sync instead of immediate delete
            cached.needsSync = true
            cached.syncStatus = "pendingDelete"
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
            predicate: #Predicate { $0.syncStatus == "pendingUpload" }
        )
        let toUpload = try modelContext.fetch(uploadDescriptor)
        
        for cached in toUpload {
            let recipe = cached.toRecipe()
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                cloudKitService.saveRecipe(recipe) { result in
                    switch result {
                    case .success:
                        Task { @MainActor in
                            cached.needsSync = false
                            cached.syncStatus = "synced"
                            try? self.modelContext.save()
                        }
                        continuation.resume()
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
        
        // Get recipes pending delete
        let deleteDescriptor = FetchDescriptor<CachedRecipe>(
            predicate: #Predicate { $0.syncStatus == "pendingDelete" }
        )
        let toDelete = try modelContext.fetch(deleteDescriptor)
        
        for cached in toDelete {
            let recipe = cached.toRecipe()
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                cloudKitService.deleteRecipe(recipe) { result in
                    switch result {
                    case .success:
                        Task { @MainActor in
                            self.modelContext.delete(cached)
                            try? self.modelContext.save()
                        }
                        continuation.resume()
                    case .failure(let error):
                        // If delete fails because record doesn't exist, still remove locally
                        if let ckError = error as? CKError, ckError.code == .unknownItem {
                            Task { @MainActor in
                                self.modelContext.delete(cached)
                                try? self.modelContext.save()
                            }
                            continuation.resume()
                        } else {
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }
        }
    }
    
    private func pullFromCloudKit() async throws {
        let recipes: [Recipe] = try await withCheckedThrowingContinuation { continuation in
            cloudKitService.fetchRecipes { result in
                switch result {
                case .success(let recipes):
                    continuation.resume(returning: recipes)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
        
        // Merge remote recipes into local cache
        for recipe in recipes {
            if let existing = try fetchCachedRecipe(byId: recipe.id) {
                // Only update if local isn't pending upload (local changes take precedence)
                if existing.syncStatus == "synced" {
                    existing.update(from: recipe)
                    existing.needsSync = false
                    existing.syncStatus = "synced"
                }
            } else {
                let cached = CachedRecipe(from: recipe)
                cached.needsSync = false
                cached.syncStatus = "synced"
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
        cached.syncStatus = "pendingUpload"
        try modelContext.save()
    }
}
