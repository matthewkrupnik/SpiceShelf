import Foundation
@testable import SpiceShelf

final class MockRecipeParserService: RecipeParserServiceProtocol, @unchecked Sendable {

    var parseRecipeCalled = false
    var urlToParse: URL?
    var errorToThrow: Error?

    func parseRecipe(from url: URL) async throws -> Recipe {
        parseRecipeCalled = true
        urlToParse = url
        if let error = errorToThrow { throw error }
        
        return Recipe(id: UUID(),
                      title: "Dummy Recipe",
                      ingredients: [
                          Ingredient(id: UUID(), name: "Ingredient 1", quantity: 1.0, units: ""),
                          Ingredient(id: UUID(), name: "Ingredient 2", quantity: 1.0, units: "")
                      ],
                      instructions: ["Step 1", "Step 2"],
                      sourceURL: url.absoluteString)
    }
}
