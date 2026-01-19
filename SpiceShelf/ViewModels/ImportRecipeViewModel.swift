import Foundation
import Combine

@MainActor
class ImportRecipeViewModel: ObservableObject {
    enum State {
        case idle
        case importing
        case success
        case error
    }

    @Published var url: String = ""
    @Published var state: State = .idle
    @Published var error: AlertError? = nil

    private let cloudKitService: CloudKitServiceProtocol
    private let recipeParserService: RecipeParserService

    init(
        recipeParserService: RecipeParserService? = nil,
        cloudKitService: CloudKitServiceProtocol? = nil
    ) {
        self.recipeParserService = recipeParserService ?? RecipeParserService()
        self.cloudKitService = cloudKitService ?? ServiceLocator.currentCloudKitService()
    }

    func importRecipe() {
        state = .importing
        error = nil

        guard let parseURL = URL(string: url) else {
            error = AlertError(underlyingError: URLError(.badURL))
            state = .error
            return
        }

        recipeParserService.parseRecipe(from: parseURL) { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }

                switch result {
                case .success(let recipe):
                    self.cloudKitService.saveRecipe(recipe) { result in
                        Task { @MainActor in
                            switch result {
                            case .success:
                                self.state = .success
                            case .failure(let error):
                                self.error = AlertError(underlyingError: error)
                                self.state = .error
                            }
                        }
                    }
                case .failure(let error):
                    self.error = AlertError(underlyingError: error)
                    self.state = .error
                }
            }
        }
    }
}
