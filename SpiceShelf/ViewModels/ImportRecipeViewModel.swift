
import Foundation
import Combine

class ImportRecipeViewModel: ObservableObject {
    @Published var urlString: String = ""
    @Published var isImporting: Bool = false
    @Published var errorMessage: String? = nil
    
    private let cloudKitService: CloudKitServiceProtocol
    private let recipeParserService: RecipeParserService
    
    init(cloudKitService: CloudKitServiceProtocol = CloudKitService(), recipeParserService: RecipeParserService = RecipeParserService()) {
        self.cloudKitService = cloudKitService
        self.recipeParserService = recipeParserService
    }
    
    func importRecipe() {
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            return
        }
        
        isImporting = true
        errorMessage = nil
        
        recipeParserService.parseRecipe(from: url) { [weak self] result in
            DispatchQueue.main.async {
                self?.isImporting = false
                switch result {
                case .success(let recipe):
                    self?.save(recipe: recipe)
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func save(recipe: Recipe) {
        cloudKitService.saveRecipe(recipe) { [weak self] (result: Result<Recipe, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    // Handle success, maybe dismiss the view
                    break
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
