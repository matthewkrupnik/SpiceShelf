import SwiftUI
import CloudKit

import SwiftUI
// CloudKit is imported but unused in this file directly if we rely on ViewModel/Recipe models,
// but recipe.imageAsset uses CKAsset which is Foundation/CloudKit.
// However, CKAsset is available via the Recipe model which imports CloudKit.
// Let's keep it if needed, but remove duplicate.
// Actually, 'import CloudKit' is already present in line 2.
// The file has:
// import SwiftUI
// import CloudKit
// ...
// No, wait. The linter said "Duplicate Imports Violation".
// Let's just remove the second one if it exists or check the file content.
// Ah, the previous replace operation might have added it again.
// Let's just clean up imports.

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
                                        destination: RecipeDetailView(viewModel: RecipeDetailViewModel(recipe: recipe))
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
                        Text("An error occurred: \(viewModel.error?.localizedDescription ?? "Unknown error")")
                        Button("Retry") {
                            viewModel.fetchRecipes()
                        }
                    }
                }
            }
            .navigationTitle("SpiceShelf")
            .navigationBarItems(
                leading: Button(action: {
                    isShowingImportRecipeView = true
                }) {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundColor(.sageGreen)
                },
                trailing: Button(action: {
                    isShowingAddRecipeView = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.sageGreen)
                        .font(.title2)
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
                    Label("\(recipe.servings)", systemImage: "person.2")
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
