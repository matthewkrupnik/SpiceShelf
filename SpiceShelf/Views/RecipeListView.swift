import SwiftUI
import CloudKit

struct RecipeListView: View {
    @StateObject private var viewModel = RecipeListViewModel()
    @State private var isShowingAddRecipeView = false
    @State private var isShowingImportRecipeView = false
    @State private var isShowingSettingsView = false
    @Namespace private var heroNamespace
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).edgesIgnoringSafeArea(.all)
                
                switch viewModel.state {
                case .loading:
                    ProgressView()
                case .loaded:
                    if viewModel.filteredRecipes.isEmpty && !viewModel.searchText.isEmpty {
                        ContentUnavailableView.search(text: viewModel.searchText)
                    } else if viewModel.recipes.isEmpty {
                        EmptyStateView()
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(viewModel.filteredRecipes) { recipe in
                                    NavigationLink(value: recipe) {
                                        RecipeCardView(recipe: recipe)
                                            .matchedTransitionSource(id: recipe.id, in: heroNamespace)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .contextMenu {
                                        Button {
                                            UIPasteboard.general.string = recipe.title
                                            HapticStyle.light.trigger()
                                        } label: {
                                            Label("Copy Title", systemImage: "doc.on.doc")
                                        }
                                        
                                        if let url = recipe.sourceURL, let shareURL = URL(string: url) {
                                            ShareLink(item: shareURL) {
                                                Label("Share Source", systemImage: "square.and.arrow.up")
                                            }
                                        }
                                        
                                        Divider()
                                        
                                        Button(role: .destructive) {
                                            viewModel.recipeToDelete = recipe
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .padding()
                        }
                        .refreshable {
                            await viewModel.refreshFromPullToRefresh()
                        }
                    }
                case .error:
                    VStack {
                        Text("An error occurred: \(String(viewModel.error?.localizedDescription ?? "Unknown error"))")
                        Button("Retry") {
                            viewModel.fetchRecipes()
                        }
                    }
                }
            }
            .navigationTitle("Spice Nook")
            .searchable(text: $viewModel.searchText, prompt: "Search recipes")
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe)
                    .navigationTransition(.zoom(sourceID: recipe.id, in: heroNamespace))
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Settings", systemImage: "gearshape") {
                        isShowingSettingsView = true
                    }
                    .glassEffect()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            isShowingImportRecipeView = true
                        } label: {
                            Label("Import from Website", systemImage: "globe")
                        }
                        Button {
                            isShowingAddRecipeView = true
                        } label: {
                            Label("Enter Manually", systemImage: "square.and.pencil")
                        }
                        Button {
                        } label: {
                            Label("AI from Image", systemImage: "camera")
                        }
                        .disabled(true)
                    } label: {
                        Label("Add Recipe", systemImage: "plus")
                    }
                    .menuStyle(.button)
                    .glassEffect()
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .sheet(isPresented: $isShowingAddRecipeView) {
                AddRecipeView()
                    .presentationBackground(.regularMaterial)
                    .presentationCornerRadius(24)
            }
            .sheet(isPresented: $isShowingImportRecipeView) {
                ImportRecipeView()
                    .presentationBackground(.regularMaterial)
                    .presentationCornerRadius(24)
            }
            .sheet(isPresented: $isShowingSettingsView) {
                SettingsView()
                    .presentationBackground(.regularMaterial)
                    .presentationCornerRadius(24)
            }
            .onAppear {
                viewModel.fetchRecipes()
            }
            .alert("Delete Recipe", isPresented: .init(
                get: { viewModel.recipeToDelete != nil },
                set: { if !$0 { viewModel.recipeToDelete = nil } }
            )) {
                Button("Cancel", role: .cancel) {
                    viewModel.recipeToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let recipe = viewModel.recipeToDelete {
                        viewModel.deleteRecipe(recipe)
                    }
                }
            } message: {
                Text("Are you sure you want to delete \"\(viewModel.recipeToDelete?.title ?? "")\"?")
            }
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "basket")
                .font(.system(size: 60))
                .foregroundColor(.sageGreen.opacity(0.5))
                .symbolEffect(.bounce, options: .repeat(2))
            Text("Your shelf is empty")
                .font(.serifHeading())
                .foregroundColor(.charcoal)
            Text("Start by adding your favorite recipes.")
                .font(.sansBody())
                .foregroundColor(.gray)
        }
    }
}

struct RecipeCardView: View {
    let recipe: Recipe
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                CachedAsyncImage(asset: recipe.imageAsset)
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                    .clipped()
                
                // Rating badge overlay with glass effect
                if let rating = recipe.aggregateRating?.ratingValue {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", rating))
                            .font(.caption2.bold())
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .glassEffect()
                    .clipShape(Capsule())
                    .padding(8)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(recipe.title)
                    .font(.serifHeading())
                    .foregroundColor(.charcoal)
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                
                HStack(spacing: 8) {
                    if let servings = recipe.servings, servings > 0 {
                        Label(String(servings), systemImage: "person.2")
                    }
                    
                    if let time = recipe.totalTime?.displayString {
                        Label(time, systemImage: "clock")
                    }
                }
                .font(.sansCaption())
                .foregroundColor(.secondaryText)
            }
            .padding(12)
            .frame(height: 80)
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .glassEffect(in: .rect(cornerRadius: 16, style: .continuous))
    }
}
