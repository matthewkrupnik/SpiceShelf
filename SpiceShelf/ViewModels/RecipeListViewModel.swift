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
    @Published var recipeToDelete: Recipe? = nil
    
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
        
        NotificationCenter.default.publisher(for: .recipeDeleted)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                if let recipe = notification.object as? Recipe {
                    self?.recipes.removeAll { $0.id == recipe.id }
                }
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

        Task {
            do {
                let recipes = try await cloudKitService.fetchRecipes()
                self.recipes = recipes
                self.state = .loaded
                self.isInitialLoad = false
            } catch {
                self.error = AlertError(underlyingError: error)
                self.state = .error
            }
        }
    }
    
    /// Refresh recipes without showing loading state (for background updates)
    private func refreshRecipes() {
        Task {
            await refreshFromPullToRefresh()
        }
    }
    
    /// Async refresh suitable for .refreshable (awaits completion before returning)
    func refreshFromPullToRefresh() async {
        do {
            let recipes = try await cloudKitService.fetchRecipes()
            if self.recipes.map(\.id) != recipes.map(\.id) ||
               self.recipes.map(\.title) != recipes.map(\.title) {
                self.recipes = recipes
            }
            self.state = .loaded
        } catch {
            // Silently fail on pull-to-refresh - keep existing data
        }
    }
    
    func forceSync() {
        Task {
            await RecipeDataStore.shared.syncWithCloudKit()
            refreshRecipes()
        }
    }
    
    func deleteRecipe(_ recipe: Recipe) {
        Task {
            do {
                try await cloudKitService.deleteRecipe(recipe)
                self.recipes.removeAll { $0.id == recipe.id }
                HapticStyle.success.trigger()
            } catch {
                self.error = AlertError(underlyingError: error)
                HapticStyle.error.trigger()
            }
        }
    }
}
