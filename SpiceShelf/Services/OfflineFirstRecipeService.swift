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
    
    func fetchRecipes(completion: @escaping (Result<[Recipe], Error>) -> Void) {
        // Return local data immediately
        do {
            let localRecipes = try dataStore.fetchAllRecipes()
            completion(.success(localRecipes))
            
            // Then sync in background (don't notify - let the pull-to-refresh handle updates)
            Task {
                await dataStore.syncWithCloudKit()
            }
        } catch {
            // If local fetch fails, try CloudKit directly
            cloudKitService.fetchRecipes(completion: completion)
        }
    }
    
    func saveRecipe(_ recipe: Recipe, completion: @escaping (Result<Recipe, Error>) -> Void) {
        // Save locally first
        do {
            try dataStore.saveRecipeLocally(recipe, needsSync: true)
            completion(.success(recipe))
            
            // Then try to sync to CloudKit in background
            Task {
                await dataStore.syncWithCloudKit()
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func updateRecipe(_ recipe: Recipe, completion: @escaping (Result<Recipe, Error>) -> Void) {
        // Update locally first
        do {
            try dataStore.saveRecipeLocally(recipe, needsSync: true)
            completion(.success(recipe))
            
            // Then try to sync to CloudKit in background
            Task {
                await dataStore.syncWithCloudKit()
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func deleteRecipe(_ recipe: Recipe, completion: @escaping (Result<Void, Error>) -> Void) {
        // Mark for deletion locally
        do {
            try dataStore.deleteRecipeLocally(recipe)
            completion(.success(()))
            
            // Then try to sync deletion to CloudKit in background
            Task {
                await dataStore.syncWithCloudKit()
            }
        } catch {
            completion(.failure(error))
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
