import Foundation

// A lightweight in-memory mock of CloudKitServiceProtocol used for UI tests.
final class MockCloudKitService: CloudKitServiceProtocol, @unchecked Sendable {
    private var storage: [String: Recipe] = [:]
    private let queue = DispatchQueue(label: "MockCloudKitService")

    init(initialRecipes: [Recipe] = []) {
        for recipe in initialRecipes {
            storage[recipe.id.uuidString] = recipe
        }
    }

    func saveRecipe(_ recipe: Recipe) async throws -> Recipe {
        storage[recipe.id.uuidString] = recipe
        return recipe
    }

    func fetchRecipes() async throws -> [Recipe] {
        Array(storage.values)
    }

    func updateRecipe(_ recipe: Recipe) async throws -> Recipe {
        guard storage[recipe.id.uuidString] != nil else {
            throw NSError(domain: "MockCloudKitService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Not found"])
        }
        storage[recipe.id.uuidString] = recipe
        return recipe
    }

    func deleteRecipe(_ recipe: Recipe) async throws {
        storage.removeValue(forKey: recipe.id.uuidString)
    }
}
