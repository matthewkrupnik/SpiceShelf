import Foundation
import CloudKit

/// Offline-first recipe service that uses SwiftData for local caching and CloudKit for sync
@MainActor
class OfflineFirstRecipeService: CloudKitServiceProtocol {
    private let dataStore: RecipeDataStore
    private let cloudKitService: CloudKitServiceProtocol
    
    init(dataStore: RecipeDataStore? = nil, cloudKitService: CloudKitServiceProtocol? = nil) {
        self.dataStore = dataStore ?? RecipeDataStore.shared
        // Use raw CloudKit service directly to avoid circular dependency with ServiceLocator
        self.cloudKitService = cloudKitService ?? CloudKitService()
    }
    
    // MARK: - CloudKitServiceProtocol
    
    func fetchRecipes() async throws -> [Recipe] {
        do {
            let localRecipes = try dataStore.fetchAllRecipes()
            Task {
                await dataStore.syncWithCloudKit()
            }
            return localRecipes
        } catch {
            return try await cloudKitService.fetchRecipes()
        }
    }
    
    func saveRecipe(_ recipe: Recipe) async throws -> Recipe {
        try dataStore.saveRecipeLocally(recipe, needsSync: true)
        Task {
            await dataStore.syncWithCloudKit()
        }
        return recipe
    }
    
    func updateRecipe(_ recipe: Recipe) async throws -> Recipe {
        try dataStore.saveRecipeLocally(recipe, needsSync: true)
        Task {
            await dataStore.syncWithCloudKit()
        }
        return recipe
    }
    
    func deleteRecipe(_ recipe: Recipe) async throws {
        try dataStore.deleteRecipeLocally(recipe)
        Task {
            await dataStore.syncWithCloudKit()
        }
    }
    
    // MARK: - Additional Methods
    
    /// Force a sync with CloudKit
    func forceSync() async {
        await dataStore.syncWithCloudKit()
    }
    
    /// Get cached image data for a recipe
    func cachedImageData(for recipeId: UUID) -> Data? {
        return dataStore.imageData(for: recipeId)
    }
}
