import Foundation
import Combine

class RecipeListViewModel: ObservableObject {
    enum State {
        case loading
        case loaded
        case error
    }

    @Published var state: State = .loading
    @Published var recipes: [Recipe] = []
    @Published var error: AlertError? = nil

    private let cloudKitService: CloudKitServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(cloudKitService: CloudKitServiceProtocol? = nil) {
        self.cloudKitService = cloudKitService ?? ServiceLocator.currentCloudKitService()
        fetchRecipes()
        
        // Listen for recipe saved notifications to refresh the list
        NotificationCenter.default.publisher(for: .recipeSaved)
            .sink { [weak self] _ in
                self?.fetchRecipes()
            }
            .store(in: &cancellables)
    }

    func fetchRecipes() {
        state = .loading
        error = nil

        cloudKitService.fetchRecipes { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let recipes):
                    self?.recipes = recipes
                    self?.state = .loaded
                case .failure(let error):
                    self?.error = AlertError(underlyingError: error)
                    self?.state = .error
                }
            }
        }
    }
}
