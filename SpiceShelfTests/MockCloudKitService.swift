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
        DispatchQueue.main.async {
            completion(.success(recipe))
            self.expectation?.fulfill()
        }
    }

    func fetchRecipes(completion: @escaping (Result<[Recipe], Error>) -> Void) {
        fetchRecipesCalled = true
        DispatchQueue.main.async {
            if let recipe = self.recipeSaved {
                completion(.success([recipe]))
            } else {
                completion(.success([]))
            }
        }
    }

    func updateRecipe(_ recipe: Recipe, completion: @escaping (Result<Recipe, Error>) -> Void) {
        updateRecipeCalled = true
        recipeSaved = recipe
        DispatchQueue.main.async {
            completion(.success(recipe))
            self.expectation?.fulfill()
        }
    }

    func deleteRecipe(_ recipe: Recipe, completion: @escaping (Result<Void, Error>) -> Void) {
        deleteRecipeCalled = true
        recipeSaved = nil
        DispatchQueue.main.async {
            completion(.success(()))
            self.expectation?.fulfill()
        }
    }
}
