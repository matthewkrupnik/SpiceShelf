import Foundation
import Combine

@MainActor
class RecipeDetailViewModel: ObservableObject {
    @Published var recipe: Recipe
    @Published var isShowingDeleteConfirmation: Bool = false
    @Published var currentServings: Int?
    @Published var completedIngredients: Set<UUID> = []
    @Published var error: AlertError?
    @Published var isLoading: Bool = false
    private let cloudKitService: CloudKitServiceProtocol

    init(recipe: Recipe, cloudKitService: CloudKitServiceProtocol? = nil) {
        self.recipe = recipe
        self.currentServings = recipe.servings
        self.cloudKitService = cloudKitService ?? ServiceLocator.currentCloudKitService()
    }

    var canScale: Bool {
        guard let servings = recipe.servings, servings > 0 else { return false }
        return true
    }

    var scaledIngredients: [Ingredient] {
        guard let recipeServings = recipe.servings, recipeServings > 0,
              let current = currentServings, current > 0 else {
            return recipe.ingredients
        }
        let scale = Double(current) / Double(recipeServings)
        return recipe.ingredients.map {
            var newIngredient = $0
            newIngredient.quantity = $0.quantity * scale
            return newIngredient
        }
    }

    func saveChanges() {
        isLoading = true
        error = nil
        print("[RecipeDetailViewModel] cloudKitService type = \(type(of: cloudKitService))")
        Task {
            do {
                let updatedRecipe = try await cloudKitService.updateRecipe(recipe)
                self.recipe = updatedRecipe
                if updatedRecipe.servings != nil {
                    self.currentServings = updatedRecipe.servings
                }
                NotificationCenter.default.post(name: .recipeSaved, object: updatedRecipe)
            } catch {
                self.error = AlertError(underlyingError: error)
            }
            self.isLoading = false
        }
    }

    func deleteRecipe(completion: (() -> Void)? = nil) {
        isLoading = true
        error = nil
        Task {
            do {
                try await cloudKitService.deleteRecipe(recipe)
                NotificationCenter.default.post(name: .recipeDeleted, object: recipe)
                completion?()
            } catch {
                self.error = AlertError(underlyingError: error)
            }
            self.isLoading = false
            self.isShowingDeleteConfirmation = false
        }
    }
}
