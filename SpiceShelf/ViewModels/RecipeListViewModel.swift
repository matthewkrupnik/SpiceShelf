import Foundation
import Combine

@MainActor
class RecipeListViewModel: ObservableObject {
    enum State {
        case loading
        case loaded
        case error
    }

    @Published var state: State = .loading
    @Published var recipes: [Recipe] = []
    @Published var error: AlertError? = nil
    @Published var searchText: String = ""
    @Published var isSyncing: Bool = false
    
    var filteredRecipes: [Recipe] {
        guard !searchText.isEmpty else { return recipes }
        let query = searchText.lowercased()
        return recipes.filter { recipe in
            recipe.title.lowercased().contains(query) ||
            recipe.ingredients.contains { $0.name.lowercased().contains(query) }
        }
    }

    private let cloudKitService: CloudKitServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private var isInitialLoad = true

    init(cloudKitService: CloudKitServiceProtocol? = nil) {
        self.cloudKitService = cloudKitService ?? ServiceLocator.currentCloudKitService()
        fetchRecipes()
        
        // Listen for recipe saved notifications to refresh the list
        NotificationCenter.default.publisher(for: .recipeSaved)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshRecipes()
            }
            .store(in: &cancellables)
        
        // Observe sync status from data store
        RecipeDataStore.shared.$isSyncing
            .receive(on: RunLoop.main)
            .assign(to: &$isSyncing)
    }

    func fetchRecipes() {
        state = .loading
        error = nil

        cloudKitService.fetchRecipes { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let recipes):
                    self?.recipes = recipes
                    self?.state = .loaded
                    self?.isInitialLoad = false
                case .failure(let error):
                    self?.error = AlertError(underlyingError: error)
                    self?.state = .error
                }
            }
        }
    }
    
    /// Refresh recipes without showing loading state (for background updates)
    private func refreshRecipes() {
        cloudKitService.fetchRecipes { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let recipes):
                    // Only update if data actually changed
                    if self?.recipes.map(\.id) != recipes.map(\.id) ||
                       self?.recipes.map(\.title) != recipes.map(\.title) {
                        self?.recipes = recipes
                    }
                    self?.state = .loaded
                case .failure:
                    // Silently fail on background refresh - keep existing data
                    break
                }
            }
        }
    }
    
    func forceSync() {
        Task {
            await RecipeDataStore.shared.syncWithCloudKit()
            refreshRecipes()
        }
    }
}
