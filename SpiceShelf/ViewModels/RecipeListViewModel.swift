import Foundation

import Combine

class RecipeListViewModel: ObservableObject {
    @Published var recipes: [Recipe] = []
    
    private let cloudKitService: CloudKitServiceProtocol
    
    init(cloudKitService: CloudKitServiceProtocol = CloudKitService()) {
        self.cloudKitService = cloudKitService
    }
    
    func fetchRecipes() {
        cloudKitService.fetchRecipes { [weak self] result in
            switch result {
            case .success(let recipes):
                DispatchQueue.main.async {
                    self?.recipes = recipes
                }
            case .failure(let error):
                // Handle error
                print(error.localizedDescription)
            }
        }
    }
}
