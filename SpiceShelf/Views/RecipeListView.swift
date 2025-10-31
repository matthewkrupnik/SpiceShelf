import SwiftUI

struct RecipeListView: View {
    @StateObject private var viewModel = RecipeListViewModel()
    @State private var isShowingAddRecipeView = false
    @State private var isShowingImportRecipeView = false

    var body: some View {
        NavigationView {
            VStack {
                switch viewModel.state {
                case .loading:
                    ProgressView()
                case .loaded:
                    if viewModel.recipes.isEmpty {
                        Text("No recipes yet. Add one!")
                    } else {
                        List(viewModel.recipes) { recipe in
                            NavigationLink(destination: RecipeDetailView(viewModel: RecipeDetailViewModel(recipe: recipe))) {
                                Text(recipe.title)
                            }
                        }
                    }
                case .error:
                    Text("An error occurred: \(viewModel.error?.localizedDescription ?? "Unknown error")")
                    Button("Retry") {
                        viewModel.fetchRecipes()
                    }
                }
            }
            .navigationTitle("Recipes")
            .navigationBarItems(
                leading: Button(action: {
                    isShowingImportRecipeView = true
                }) {
                    Image(systemName: "square.and.arrow.down")
                },
                trailing: Button(action: {
                    isShowingAddRecipeView = true
                }) {
                    // Use a labeled button so the title is visible to UI tests and VoiceOver.
                    Label("Add Recipe", systemImage: "plus")
                }
                .accessibilityIdentifier("Add Recipe")
                .accessibilityLabel("Add Recipe")
            )
            .sheet(isPresented: $isShowingAddRecipeView) {
                AddRecipeView()
            }
            .sheet(isPresented: $isShowingImportRecipeView) {
                ImportRecipeView()
            }
            .onAppear {
                viewModel.fetchRecipes()
            }
        }
    }
}
