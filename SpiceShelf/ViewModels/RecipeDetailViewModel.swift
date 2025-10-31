import Foundation
import Combine

class RecipeDetailViewModel: ObservableObject {
    enum State {
        case idle
        case saving
        case deleting
        case error
    }

    @Published var state: State = .idle
    @Published var recipe: Recipe
    @Published var isShowingDeleteConfirmation: Bool = false
    @Published var error: AlertError? = nil

    private let cloudKitService: CloudKitServiceProtocol

    init(recipe: Recipe, cloudKitService: CloudKitServiceProtocol? = nil) {
        self.recipe = recipe
        self.cloudKitService = cloudKitService ?? ServiceLocator.currentCloudKitService()
    }

    func saveChanges() {
        state = .saving
        error = nil

        cloudKitService.updateRecipe(recipe) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let updatedRecipe):
                    self?.recipe = updatedRecipe
                    self?.state = .idle
                    // Notify other parts of the app so they can refresh after an update
                    NotificationCenter.default.post(name: .recipeSaved, object: updatedRecipe)
                case .failure(let error):
                    self?.error = AlertError(underlyingError: error)
                    self?.state = .error
                }
            }
        }
    }

    func deleteRecipe(completion: (() -> Void)? = nil) {
        state = .deleting
        error = nil

        cloudKitService.deleteRecipe(recipe) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.state = .idle
                    completion?()
                case .failure(let error):
                    self?.error = AlertError(underlyingError: error)
                    self?.state = .error
                }
                // Ensure the confirmation flag is reset
                self?.isShowingDeleteConfirmation = false
            }
        }
    }
}
