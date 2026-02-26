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
    private let recipeParserService: RecipeParserServiceProtocol

    init(
        recipeParserService: RecipeParserServiceProtocol? = nil,
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

        Task {
            do {
                let recipe = try await recipeParserService.parseRecipe(from: parseURL)
                let savedRecipe = try await cloudKitService.saveRecipe(recipe)
                self.state = .success
                NotificationCenter.default.post(name: .recipeSaved, object: savedRecipe)
            } catch {
                self.error = AlertError(underlyingError: error)
                self.state = .error
            }
        }
    }
}
