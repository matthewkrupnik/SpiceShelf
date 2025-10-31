import Foundation
@testable import SpiceShelf

@MainActor final class MockRecipeParserService: RecipeParserService {

    var parseRecipeCalled = false
    var urlToParse: URL?

    override func parseRecipe(from url: URL, completion: @escaping (Result<Recipe, Error>) -> Void) {
        parseRecipeCalled = true
        urlToParse = url
        
        // Call completion asynchronously on the main thread to match real service behavior
        DispatchQueue.main.async {
            let dummyRecipe = Recipe(id: UUID(),
                                     title: "Dummy Recipe",
                                     ingredients: ["Ingredient 1", "Ingredient 2"],
                                     instructions: ["Step 1", "Step 2"],
                                     sourceURL: url.absoluteString)
            completion(.success(dummyRecipe))
        }
    }
}
