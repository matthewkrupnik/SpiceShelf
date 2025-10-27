import Foundation

import Combine

class AddRecipeViewModel: ObservableObject {
    private let cloudKitService: CloudKitServiceProtocol
    
    init(cloudKitService: CloudKitServiceProtocol = CloudKitService()) {
        self.cloudKitService = cloudKitService
    }
    
    func saveRecipe(title: String, ingredients: String, instructions: String) {
        let ingredientsArray = ingredients.components(separatedBy: .newlines)
        let instructionsArray = instructions.components(separatedBy: .newlines)
        let recipe = Recipe(id: UUID(), title: title, ingredients: ingredientsArray, instructions: instructionsArray, sourceURL: nil)
        
        cloudKitService.saveRecipe(recipe) { (result: Result<Recipe, Error>) in
            // Handle result
        }
    }
}
