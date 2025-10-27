import SwiftUI

struct RecipeDetailView: View {
    @StateObject private var viewModel: RecipeDetailViewModel
    @State private var isEditing = false
    
    init(recipe: Recipe) {
        _viewModel = StateObject(wrappedValue: RecipeDetailViewModel(recipe: recipe))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(viewModel.recipe.title)
                    .font(.largeTitle)
                
                Text("Ingredients")
                    .font(.title2)
                ForEach(viewModel.recipe.ingredients, id: \.self) { ingredient in
                    Text("- \(ingredient)")
                }
                
                Text("Instructions")
                    .font(.title2)
                ForEach(viewModel.recipe.instructions, id: \.self) { instruction in
                    Text(instruction)
                }
                Button("Delete") {
                    viewModel.deleteRecipe()
                }
                .foregroundColor(.red)
            }
            .padding()
        }
        .navigationTitle(viewModel.recipe.title)
        .navigationBarItems(trailing: Button("Edit") {
            isEditing = true
        })
        .sheet(isPresented: $isEditing) {
            EditRecipeView(viewModel: viewModel)
        }
    }
}

struct EditRecipeView: View {
    @ObservedObject var viewModel: RecipeDetailViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Title", text: $viewModel.recipe.title)
                // How to edit arrays of strings in a TextField?
                // This needs a more complex UI.
            }
            .navigationTitle("Edit Recipe")
            .navigationBarItems(trailing: Button("Save") {
                viewModel.updateRecipe()
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
