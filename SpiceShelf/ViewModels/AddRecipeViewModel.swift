import Foundation

enum ValidationError: Error, LocalizedError {
    case emptyTitle

    var errorDescription: String? {
        switch self {
        case .emptyTitle:
            return NSLocalizedString("The recipe title cannot be empty.", comment: "")
        }
    }
}


import Combine

class AddRecipeViewModel: ObservableObject {
    private let cloudKitService: CloudKitServiceProtocol

    // Published property so views can react when a recipe is saved
    @Published var savedRecipe: Recipe? = nil
    @Published var error: AlertError? = nil

    // Allow injecting a service (tests). If nil, use the ServiceLocator to pick the current service.
    init(cloudKitService: CloudKitServiceProtocol? = nil) {
        self.cloudKitService = cloudKitService ?? ServiceLocator.currentCloudKitService()
    }

    func saveRecipe(title: String, ingredients: [Ingredient], instructions: [String]) {
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.error = AlertError(underlyingError: ValidationError.emptyTitle)
            return
        }

        let recipe = Recipe(id: UUID(),
                              title: title,
                              ingredients: ingredients,
                              instructions: instructions,
                              sourceURL: nil)

        cloudKitService.saveRecipe(recipe) { (result: Result<Recipe, Error>) in
            switch result {
            case .success(let r):
                DispatchQueue.main.async {
                    self.savedRecipe = r
                    // Notify other parts of the app so they can refresh after a save
                    NotificationCenter.default.post(name: .recipeSaved, object: r)
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.error = AlertError(underlyingError: error)
                }
            }
        }
    }
}
