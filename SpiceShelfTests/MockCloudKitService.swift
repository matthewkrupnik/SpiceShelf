import Foundation
import XCTest
@testable import SpiceShelf

final class MockCloudKitService: CloudKitServiceProtocol, @unchecked Sendable {
    var saveRecipeCalled = false
    var fetchRecipesCalled = false
    var updateRecipeCalled = false
    var deleteRecipeCalled = false
    var recipeSaved: Recipe?
    var expectation: XCTestExpectation?
    var errorToThrow: Error?

    func saveRecipe(_ recipe: Recipe) async throws -> Recipe {
        saveRecipeCalled = true
        if let error = errorToThrow { throw error }
        recipeSaved = recipe
        print("[MockCloudKitService] saveRecipe called for \(recipe.title)")
        expectation?.fulfill()
        return recipe
    }

    func fetchRecipes() async throws -> [Recipe] {
        fetchRecipesCalled = true
        if let error = errorToThrow { throw error }
        if let recipe = self.recipeSaved {
            print("[MockCloudKitService] fetchRecipes returning 1 saved recipe")
            return [recipe]
        } else {
            print("[MockCloudKitService] fetchRecipes returning 0 recipes")
            return []
        }
    }

    func updateRecipe(_ recipe: Recipe) async throws -> Recipe {
        updateRecipeCalled = true
        if let error = errorToThrow { throw error }
        recipeSaved = recipe
        print("[MockCloudKitService] updateRecipe called for \(recipe.title)")
        expectation?.fulfill()
        return recipe
    }

    func deleteRecipe(_ recipe: Recipe) async throws {
        deleteRecipeCalled = true
        if let error = errorToThrow { throw error }
        recipeSaved = nil
        print("[MockCloudKitService] deleteRecipe called for \(recipe.title)")
        expectation?.fulfill()
    }
}
