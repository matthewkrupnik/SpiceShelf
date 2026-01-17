import Foundation
import XCTest
@testable import SpiceShelf

final class MockCloudKitService: CloudKitServiceProtocol {
    var saveRecipeCalled = false
    var fetchRecipesCalled = false
    var updateRecipeCalled = false
    var deleteRecipeCalled = false
    var recipeSaved: Recipe?
    var expectation: XCTestExpectation?

    func saveRecipe(_ recipe: Recipe, completion: @escaping (Result<Recipe, Error>) -> Void) {
        saveRecipeCalled = true
        recipeSaved = recipe
        // Call completion immediately so tests don't depend on the main runloop scheduling
        print("[MockCloudKitService] saveRecipe called for \(recipe.title)")
        completion(.success(recipe))
        self.expectation?.fulfill()
    }

    func fetchRecipes(completion: @escaping (Result<[Recipe], Error>) -> Void) {
        fetchRecipesCalled = true
        if let recipe = self.recipeSaved {
            print("[MockCloudKitService] fetchRecipes returning 1 saved recipe")
            completion(.success([recipe]))
        } else {
            print("[MockCloudKitService] fetchRecipes returning 0 recipes")
            completion(.success([]))
        }
    }

    func updateRecipe(_ recipe: Recipe, completion: @escaping (Result<Recipe, Error>) -> Void) {
        updateRecipeCalled = true
        recipeSaved = recipe
        // Call completion immediately to ensure the test's expectation is fulfilled reliably
        print("[MockCloudKitService] updateRecipe called for \(recipe.title)")
        completion(.success(recipe))
        self.expectation?.fulfill()
    }

    func deleteRecipe(_ recipe: Recipe, completion: @escaping (Result<Void, Error>) -> Void) {
        deleteRecipeCalled = true
        recipeSaved = nil
        print("[MockCloudKitService] deleteRecipe called for \(recipe.title)")
        completion(.success(()))
        self.expectation?.fulfill()
    }
}
