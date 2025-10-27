import Foundation
@testable import SpiceShelf

class MockCloudKitService: CloudKitServiceProtocol {
    var saveRecipeCalled = false
    var fetchRecipesCalled = false
    var updateRecipeCalled = false
    var deleteRecipeCalled = false
    var recipeSaved: Recipe?
    
    func saveRecipe(_ recipe: Recipe, completion: @escaping (Result<Recipe, Error>) -> Void) {
        saveRecipeCalled = true
        recipeSaved = recipe
        completion(.success(recipe))
    }
    
    func fetchRecipes(completion: @escaping (Result<[Recipe], Error>) -> Void) {
        fetchRecipesCalled = true
        if let recipe = recipeSaved {
            completion(.success([recipe]))
        } else {
            completion(.success([]))
        }
    }

    func updateRecipe(_ recipe: Recipe, completion: @escaping (Result<Recipe, Error>) -> Void) {
        updateRecipeCalled = true
        recipeSaved = recipe
        completion(.success(recipe))
    }
    
    func deleteRecipe(_ recipe: Recipe, completion: @escaping (Result<Void, Error>) -> Void) {
        deleteRecipeCalled = true
        recipeSaved = nil
        completion(.success(()))
    }
}