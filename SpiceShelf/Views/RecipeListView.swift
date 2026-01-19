import SwiftUI
import CloudKit

struct RecipeListView: View {
    @StateObject private var viewModel = RecipeListViewModel()
    @State private var isShowingAddRecipeView = false
    @State private var isShowingImportRecipeView = false
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Color.offWhite.edgesIgnoringSafeArea(.all)
                
                switch viewModel.state {
                case .loading:
                    ProgressView()
                case .loaded:
                    if viewModel.recipes.isEmpty {
                        EmptyStateView {
                            isShowingAddRecipeView = true
                        }
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(viewModel.recipes) { recipe in
                                    NavigationLink(
                                        destination: RecipeDetailView(recipe: recipe)
                                    ) {
                                        RecipeCardView(recipe: recipe)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding()
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
            .navigationTitle("SpiceShelf")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Import Recipe", systemImage: "square.and.arrow.down") {
                        isShowingImportRecipeView = true
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Recipe", systemImage: "plus") {
                        isShowingAddRecipeView = true
                    }
                }
            }
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

struct EmptyStateView: View {
    var action: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "basket")
                .font(.system(size: 60))
                .foregroundColor(.sageGreen.opacity(0.5))
            Text("Your shelf is empty")
                .font(.serifHeading())
                .foregroundColor(.charcoal)
            Text("Start by adding your favorite recipes.")
                .font(.sansBody())
                .foregroundColor(.gray)
            Button(action: action) {
                Text("Add First Recipe")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.sageGreen)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 40)
        }
    }
}

struct RecipeCardView: View {
    let recipe: Recipe
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let imageAsset = recipe.imageAsset,
               let fileURL = imageAsset.fileURL,
               let data = try? Data(contentsOf: fileURL),
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 160)
                    .clipped()
            } else {
                ZStack {
                    Color.sageGreen.opacity(0.1)
                    Image(systemName: "fork.knife")
                        .font(.largeTitle)
                        .foregroundColor(.sageGreen)
                }
                .frame(height: 160)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(recipe.title)
                    .font(.serifHeading())
                    .foregroundColor(.charcoal)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack {
                    Label(String(recipe.servings ?? 0), systemImage: "person.2")
                    Spacer()
                    Image(systemName: "clock") // Placeholder
                }
                .font(.sansCaption())
                .foregroundColor(.gray)
            }
            .padding(12)
            .background(Color.cardBackground)
        }
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}
