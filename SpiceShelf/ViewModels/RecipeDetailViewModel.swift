import Foundation
import Combine

class RecipeDetailViewModel: ObservableObject {
    @Published var recipe: Recipe
    @Published var isShowingDeleteConfirmation: Bool = false
    @Published var currentServings: Int
    @Published var completedIngredients: Set<UUID> = []
    private let cloudKitService: CloudKitServiceProtocol

    init(recipe: Recipe, cloudKitService: CloudKitServiceProtocol? = nil) {
        self.recipe = recipe
        self.currentServings = recipe.servings
        self.cloudKitService = cloudKitService ?? ServiceLocator.currentCloudKitService()
    }

    var scaledIngredients: [Ingredient] {
        guard recipe.servings > 0 else { return recipe.ingredients }
        let scale = Double(currentServings) / Double(recipe.servings)
        return recipe.ingredients.map {
            var newIngredient = $0
            newIngredient.quantity = $0.quantity * scale
            return newIngredient
        }
    }

    func saveChanges() {
        print("[RecipeDetailViewModel] cloudKitService type = \(type(of: cloudKitService))")
        cloudKitService.updateRecipe(recipe) { [weak self] result in
            let applyResult = {
                switch result {
                case .success(let updatedRecipe):
                    self?.recipe = updatedRecipe
                    self?.currentServings = updatedRecipe.servings
                    // Notify other parts of the app so they can refresh after an update
                    NotificationCenter.default.post(name: .recipeSaved, object: updatedRecipe)
                case .failure(_):
                    // Handle error if needed
                    break
                }
            }

            if Thread.isMainThread {
                applyResult()
            } else {
                DispatchQueue.main.async(execute: applyResult)
            }
        }
    }

    // Make completion optional with a default so callers (including tests) can omit it.
    func deleteRecipe(completion: (() -> Void)? = nil) {
        cloudKitService.deleteRecipe(recipe) { [weak self] result in
            let applyResult = {
                switch result {
                case .success:
                    completion?()
                case .failure(_):
                    // Optionally handle error (e.g., show an alert)
                    break
                }
                // Ensure the confirmation flag is reset
                self?.isShowingDeleteConfirmation = false
            }

            if Thread.isMainThread {
                applyResult()
            } else {
                DispatchQueue.main.async(execute: applyResult)
            }
        }
    }
}
