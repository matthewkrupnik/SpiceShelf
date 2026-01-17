import Foundation

// A lightweight in-memory mock of CloudKitServiceProtocol used for UI tests.
// Saves recipes to memory and calls completion handlers asynchronously on the main queue.
final class MockCloudKitService: CloudKitServiceProtocol {
    private var storage: [String: Recipe] = [:]
    private let queue = DispatchQueue(label: "MockCloudKitService")
    init(initialRecipes: [Recipe] = []) {
        for recipe in initialRecipes {
            storage[recipe.id.uuidString] = recipe
        }
    }

    func saveRecipe(_ recipe: Recipe, completion: @escaping (Result<Recipe, Error>) -> Void) {
        queue.async {
            self.storage[recipe.id.uuidString] = recipe
            DispatchQueue.main.async {
                completion(.success(recipe))
            }
        }
    }

    func fetchRecipes(completion: @escaping (Result<[Recipe], Error>) -> Void) {
        queue.async {
            let recipes = Array(self.storage.values)
            DispatchQueue.main.async {
                completion(.success(recipes))
            }
        }
    }

    func updateRecipe(_ recipe: Recipe, completion: @escaping (Result<Recipe, Error>) -> Void) {
        queue.async {
            guard self.storage[recipe.id.uuidString] != nil else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "MockCloudKitService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Not found"])))
                }
                return
            }

            self.storage[recipe.id.uuidString] = recipe
            DispatchQueue.main.async {
                completion(.success(recipe))
            }
        }
    }

    func deleteRecipe(_ recipe: Recipe, completion: @escaping (Result<Void, Error>) -> Void) {
        queue.async {
            self.storage.removeValue(forKey: recipe.id.uuidString)
            DispatchQueue.main.async {
                completion(.success(()))
            }
        }
    }
}
