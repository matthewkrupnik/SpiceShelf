import Foundation

import Combine

class RecipeDetailViewModel: ObservableObject {
    @Published var recipe: Recipe
    
    private let cloudKitService: CloudKitServiceProtocol
    
    init(recipe: Recipe, cloudKitService: CloudKitServiceProtocol = CloudKitService()) {
        self.recipe = recipe
        self.cloudKitService = cloudKitService
    }
    
    func deleteRecipe() {
        cloudKitService.deleteRecipe(recipe) { (result: Result<Void, Error>) in
            // Handle result
        }
    }

    func updateRecipe() {
        cloudKitService.updateRecipe(recipe) { result in
            // Handle result
        }
    }
}
